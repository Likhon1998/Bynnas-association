<?php

namespace App\Http\Controllers\Admin;

use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\MemberDue;
use App\Models\Payment;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\PaymentService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Throwable;

class PaymentController extends Controller
{
    public function __construct(
        private readonly PaymentService $payments,
        private readonly FinancePolicy $policy,
    ) {}

    public function index(Request $request): View
    {
        abort_unless($this->policy->viewAnyFinancial($request->user()), 403);

        $filters = [
            'search' => $request->string('search')->toString() ?: null,
            'receipt_number' => $request->string('receipt_number')->toString() ?: null,
            'status' => $request->string('status')->toString() ?: null,
            'from' => $request->string('from')->toString() ?: null,
            'to' => $request->string('to')->toString() ?: null,
            'user_id' => $request->filled('user_id') ? (int) $request->integer('user_id') : null,
        ];

        $payments = $this->payments->paginateAll(
            perPage: 15,
            filters: $filters,
        );

        return view('payments.index', [
            'payments' => $payments,
            'filters' => $filters,
            'statuses' => PaymentStatus::cases(),
        ]);
    }

    public function create(Request $request): View
    {
        abort_unless($this->policy->recordPayment($request->user()), 403);

        $memberId = $request->filled('member') ? (int) $request->integer('member') : null;
        $member = $memberId
            ? User::query()->where('role', UserRole::Member)->whereKey($memberId)->first()
            : null;

        $outstandingDues = collect();
        if ($member !== null) {
            $outstandingDues = MemberDue::query()
                ->with('period')
                ->where('user_id', $member->id)
                ->whereNotIn('status', ['voided', 'paid'])
                ->orderBy('id')
                ->get();
        }

        return view('payments.create', [
            'member' => $member,
            'outstandingDues' => $outstandingDues,
            'methods' => PaymentMethod::cases(),
            'idempotencyKey' => (string) Str::uuid(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($this->policy->recordPayment($request->user()), 403);

        $validated = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'amount' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'method' => ['required', Rule::in(PaymentMethod::values())],
            'received_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'idempotency_key' => ['required', 'string', 'max:100'],
            'allocations' => ['nullable', 'array'],
            'allocations.*.member_due_id' => ['required_with:allocations', 'integer', 'exists:member_dues,id'],
            'allocations.*.amount' => ['nullable', 'regex:/^\d+(\.\d{1,2})?$/'],
        ]);

        $allocations = collect($validated['allocations'] ?? [])
            ->filter(fn (array $row) => filled($row['amount'] ?? null))
            ->map(fn (array $row) => [
                'member_due_id' => (int) $row['member_due_id'],
                'amount' => $row['amount'],
            ])
            ->values()
            ->all();

        try {
            $payment = $this->payments->post($request->user(), [
                ...$validated,
                'allocations' => $allocations,
            ]);
        } catch (Throwable $e) {
            return back()
                ->withInput()
                ->withErrors(['amount' => $e->getMessage()]);
        }

        $message = $payment->wasRecentlyCreated
            ? 'Payment recorded successfully.'
            : 'Existing payment returned for the same idempotency key (duplicate submission prevented).';

        return redirect()
            ->route('payments.show', $payment)
            ->with('status', $message);
    }

    public function show(Request $request, Payment $payment): View
    {
        $payment->loadMissing(['member.memberProfile', 'allocations.memberDue.period', 'recordedBy', 'reversedBy']);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $payment->member), 403);

        return view('payments.show', compact('payment'));
    }

    public function reverse(Request $request, Payment $payment): RedirectResponse
    {
        abort_unless($this->policy->reversePayment($request->user(), $payment), 403);

        $validated = $request->validate([
            'reason' => ['required', 'string', 'min:3', 'max:1000'],
        ]);

        try {
            $this->payments->reverse($request->user(), $payment, $validated['reason']);
        } catch (Throwable $e) {
            return back()->withErrors(['reason' => $e->getMessage()]);
        }

        return redirect()
            ->route('payments.show', $payment)
            ->with('status', 'Payment reversed. History preserved.');
    }
}
