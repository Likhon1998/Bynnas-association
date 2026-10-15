<?php

namespace App\Services\Finance;

use App\Enums\MemberDueStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Jobs\NotifyPaymentRecordedJob;
use App\Models\MemberDue;
use App\Models\Payment;
use App\Models\PaymentAllocation;
use App\Models\User;
use App\Support\Money;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use LogicException;

class PaymentService
{
    public function __construct(
        private readonly ReceiptNumberGenerator $receipts,
        private readonly FinancialAuditLogger $audit,
    ) {}

    /**
     * Post a payment with optional explicit allocations.
     *
     * @param  array{
     *     user_id: int,
     *     amount: string|int,
     *     method: string,
     *     received_at?: string|null,
     *     notes?: string|null,
     *     currency?: string,
     *     idempotency_key: string,
     *     allocations?: list<array{member_due_id: int, amount: string|int}>,
     * }  $data
     */
    public function post(User $actor, array $data): Payment
    {
        $idempotencyKey = $data['idempotency_key'];

        $existing = Payment::query()
            ->where('idempotency_key', $idempotencyKey)
            ->with(['allocations.memberDue', 'member'])
            ->first();

        if ($existing !== null) {
            return $existing;
        }

        $payment = DB::transaction(function () use ($actor, $data, $idempotencyKey) {
            $locked = Payment::query()
                ->where('idempotency_key', $idempotencyKey)
                ->lockForUpdate()
                ->first();

            if ($locked !== null) {
                return $locked->load(['allocations.memberDue', 'member']);
            }

            $member = User::query()->whereKey($data['user_id'])->lockForUpdate()->firstOrFail();
            if (! $member->isMember()) {
                throw new InvalidArgumentException('Payments can only be recorded for members.');
            }
            if (! $member->is_active) {
                throw new LogicException('Cannot record payments for inactive members.');
            }

            $amount = Money::normalize($data['amount']);
            if (! Money::isPositive($amount)) {
                throw new InvalidArgumentException('Payment amount must be greater than zero.');
            }

            $method = PaymentMethod::from($data['method']);
            $allocationsInput = $data['allocations'] ?? [];

            $allocationTotal = Money::normalize('0');
            foreach ($allocationsInput as $row) {
                $allocationTotal = Money::add($allocationTotal, Money::normalize($row['amount']));
            }

            if (Money::compare($allocationTotal, $amount) === 1) {
                throw new InvalidArgumentException('Sum of allocations cannot exceed payment amount.');
            }

            $payment = Payment::query()->create([
                'user_id' => $member->id,
                'amount' => $amount,
                'currency' => $data['currency'] ?? 'BDT',
                'method' => $method,
                'received_at' => $data['received_at'] ?? now(),
                'recorded_by' => $actor->id,
                'status' => PaymentStatus::Posted,
                'receipt_number' => $this->receipts->generate(),
                'idempotency_key' => $idempotencyKey,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($allocationsInput as $row) {
                $this->allocateToDue($payment, (int) $row['member_due_id'], Money::normalize($row['amount']));
            }

            $this->audit->log($actor, 'payment.posted', $payment, null, $payment->fresh()->toArray(), [
                'allocations' => $allocationsInput,
            ]);

            return $payment->load(['allocations.memberDue', 'member', 'recordedBy']);
        });

        if ($payment->wasRecentlyCreated) {
            NotifyPaymentRecordedJob::dispatch($payment->id);
        }

        return $payment;
    }

    public function reverse(User $actor, Payment $payment, string $reason): Payment
    {
        return DB::transaction(function () use ($actor, $payment, $reason) {
            $payment = Payment::query()->whereKey($payment->id)->lockForUpdate()->firstOrFail();

            if ($payment->status === PaymentStatus::Reversed) {
                throw new LogicException('Payment is already reversed.');
            }

            $before = $payment->toArray();

            $allocations = PaymentAllocation::query()
                ->where('payment_id', $payment->id)
                ->where('is_reversed', false)
                ->lockForUpdate()
                ->get();

            foreach ($allocations as $allocation) {
                $due = MemberDue::query()->whereKey($allocation->member_due_id)->lockForUpdate()->firstOrFail();

                if ($due->status === MemberDueStatus::Voided) {
                    throw new LogicException('Cannot reverse allocation against a voided due.');
                }

                $dueBefore = $due->toArray();
                $due->amount_allocated = Money::sub((string) $due->amount_allocated, (string) $allocation->amount);
                $due->refreshStatusFromAllocation();
                $due->save();

                $allocation->is_reversed = true;
                $allocation->save();

                $this->audit->log($actor, 'payment_allocation.reversed', $allocation, [
                    'is_reversed' => false,
                    'amount' => $allocation->amount,
                ], [
                    'is_reversed' => true,
                    'amount' => $allocation->amount,
                ], ['reason' => $reason]);

                $this->audit->log($actor, 'member_due.allocation_reduced', $due, $dueBefore, $due->fresh()->toArray());
            }

            $payment->forceFill([
                'status' => PaymentStatus::Reversed,
                'reversed_at' => now(),
                'reversed_by' => $actor->id,
                'reversal_reason' => $reason,
            ])->save();

            $this->audit->log($actor, 'payment.reversed', $payment, $before, $payment->fresh()->toArray(), [
                'reason' => $reason,
            ]);

            return $payment->refresh()->load(['allocations.memberDue', 'member', 'reversedBy']);
        });
    }

    private function allocateToDue(Payment $payment, int $memberDueId, string $amount): PaymentAllocation
    {
        if (! Money::isPositive($amount)) {
            throw new InvalidArgumentException('Allocation amount must be greater than zero.');
        }

        $due = MemberDue::query()->whereKey($memberDueId)->lockForUpdate()->firstOrFail();

        if ($due->user_id !== $payment->user_id) {
            throw new InvalidArgumentException('Allocation due must belong to the paying member.');
        }

        if ($due->status === MemberDueStatus::Voided) {
            throw new InvalidArgumentException('Cannot allocate to a voided due.');
        }

        $outstanding = $due->outstandingBalance();
        if (Money::compare($amount, $outstanding) === 1) {
            throw new InvalidArgumentException('Allocation exceeds outstanding balance on due.');
        }

        $allocation = PaymentAllocation::query()->create([
            'payment_id' => $payment->id,
            'member_due_id' => $due->id,
            'amount' => $amount,
            'is_reversed' => false,
        ]);

        $due->amount_allocated = Money::add((string) $due->amount_allocated, $amount);
        $due->refreshStatusFromAllocation();
        $due->save();

        return $allocation;
    }

    public function paginateForMember(User $member, int $perPage = 15): LengthAwarePaginator
    {
        return Payment::query()
            ->with(['allocations.memberDue.period', 'recordedBy'])
            ->where('user_id', $member->id)
            ->latest('received_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * @param  array{
     *     user_id?: int|null,
     *     status?: string|null,
     *     search?: string|null,
     *     receipt_number?: string|null,
     *     from?: string|null,
     *     to?: string|null,
     * }  $filters
     */
    public function paginateAll(
        ?int $userId = null,
        ?string $status = null,
        int $perPage = 15,
        array $filters = [],
    ): LengthAwarePaginator {
        $userId = $filters['user_id'] ?? $userId;
        $status = $filters['status'] ?? $status;
        $search = $filters['search'] ?? null;
        $receipt = $filters['receipt_number'] ?? null;
        $from = $filters['from'] ?? null;
        $to = $filters['to'] ?? null;

        $query = Payment::query()
            ->with(['member', 'allocations.memberDue.period', 'recordedBy'])
            ->latest('received_at')
            ->latest('id');

        if ($userId !== null) {
            $query->where('user_id', $userId);
        }

        if (filled($status)) {
            $query->where('status', $status);
        }

        if (filled($receipt)) {
            $query->where('receipt_number', 'like', '%'.$receipt.'%');
        }

        if (filled($from)) {
            $query->whereDate('received_at', '>=', $from);
        }

        if (filled($to)) {
            $query->whereDate('received_at', '<=', $to);
        }

        if (filled($search)) {
            $term = '%'.$search.'%';
            $query->where(function ($builder) use ($term) {
                $builder->where('receipt_number', 'like', $term)
                    ->orWhereHas('member', function ($memberQuery) use ($term) {
                        $memberQuery->where('name', 'like', $term)
                            ->orWhere('member_id', 'like', $term)
                            ->orWhere('email', 'like', $term);
                    });
            });
        }

        return $query->paginate($perPage)->withQueryString();
    }

    public function findByReceipt(string $receiptNumber): ?Payment
    {
        return Payment::query()
            ->with(['allocations.memberDue', 'member'])
            ->where('receipt_number', $receiptNumber)
            ->first();
    }
}
