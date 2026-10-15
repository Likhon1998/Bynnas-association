<?php

namespace App\Services\Finance;

use App\Enums\UserRole;
use App\Models\FinancialChangeRequest;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class FinancialApprovalService
{
    public function __construct(
        private readonly PaymentService $payments,
    ) {}

    public function requestPaymentReverse(User $actor, Payment $payment, string $reason): FinancialChangeRequest
    {
        if (! $payment->isPosted()) {
            throw new RuntimeException('Only posted payments can be reversed.');
        }

        $existing = FinancialChangeRequest::query()
            ->where('type', 'payment_reverse')
            ->where('payment_id', $payment->id)
            ->where('status', 'pending')
            ->first();

        if ($existing !== null) {
            return $existing->load(['payment', 'requester']);
        }

        return FinancialChangeRequest::query()->create([
            'type' => 'payment_reverse',
            'payment_id' => $payment->id,
            'requested_by' => $actor->id,
            'status' => 'pending',
            'reason' => $reason,
        ])->load(['payment', 'requester']);
    }

    public function approve(User $reviewer, FinancialChangeRequest $request, ?string $note = null): FinancialChangeRequest
    {
        if (! $reviewer->hasRole(UserRole::SuperAdmin, UserRole::Admin)) {
            throw new RuntimeException('Only Admin or Super Admin can approve.');
        }

        if ($request->status !== 'pending') {
            throw new RuntimeException('Request is not pending.');
        }

        return DB::transaction(function () use ($reviewer, $request, $note) {
            if ($request->type === 'payment_reverse') {
                $payment = Payment::query()->findOrFail($request->payment_id);
                $this->payments->reverse($reviewer, $payment, $request->reason);
            }

            $request->forceFill([
                'status' => 'approved',
                'reviewed_by' => $reviewer->id,
                'review_note' => $note,
                'reviewed_at' => now(),
            ])->save();

            return $request->fresh(['payment', 'requester', 'reviewer']);
        });
    }

    public function reject(User $reviewer, FinancialChangeRequest $request, ?string $note = null): FinancialChangeRequest
    {
        if (! $reviewer->hasRole(UserRole::SuperAdmin, UserRole::Admin)) {
            throw new RuntimeException('Only Admin or Super Admin can reject.');
        }

        if ($request->status !== 'pending') {
            throw new RuntimeException('Request is not pending.');
        }

        $request->forceFill([
            'status' => 'rejected',
            'reviewed_by' => $reviewer->id,
            'review_note' => $note,
            'reviewed_at' => now(),
        ])->save();

        return $request->fresh(['payment', 'requester', 'reviewer']);
    }
}
