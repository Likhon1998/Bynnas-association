<?php

namespace App\Services\Finance;

use App\Enums\MemberDueStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\DuePeriod;
use App\Models\MemberDue;
use App\Models\Payment;
use App\Models\User;
use App\Support\Money;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * Authoritative financial reporting. All money totals are computed server-side.
 */
class ReportService
{
    /**
     * Organization / role dashboard summary.
     *
     * @return array{
     *     role: string,
     *     currency: string,
     *     filters: array{from: string|null, to: string|null},
     *     active_members: int,
     *     total_members: int,
     *     expected_dues: string,
     *     actual_collections: string,
     *     allocated_to_dues: string,
     *     outstanding: string,
     *     payment_status: array{pending: int, partial: int, paid: int, voided: int},
     *     recent_payments_count: int,
     * }
     */
    public function dashboardSummary(?string $from = null, ?string $to = null, ?User $forMember = null): array
    {
        [$from, $to] = $this->normalizeDateRange($from, $to);

        $memberScopeId = $forMember?->id;

        $activeMembers = User::query()
            ->where('role', UserRole::Member)
            ->where('is_active', true)
            ->when($memberScopeId, fn (Builder $q) => $q->whereKey($memberScopeId))
            ->count();

        $totalMembers = User::query()
            ->where('role', UserRole::Member)
            ->when($memberScopeId, fn (Builder $q) => $q->whereKey($memberScopeId))
            ->count();

        $duesQuery = $this->duesBaseQuery($from, $to, $memberScopeId);
        $expected = $this->sumDecimal($duesQuery->clone()->where('status', '!=', MemberDueStatus::Voided), 'amount_due');
        $allocated = $this->sumDecimal($duesQuery->clone()->where('status', '!=', MemberDueStatus::Voided), 'amount_allocated');
        $outstanding = Money::sub($expected, $allocated);

        $statusCounts = [
            MemberDueStatus::Pending->value => 0,
            MemberDueStatus::Partial->value => 0,
            MemberDueStatus::Paid->value => 0,
            MemberDueStatus::Voided->value => 0,
        ];

        $statusRows = $duesQuery->clone()
            ->selectRaw('status, COUNT(*) as aggregate')
            ->groupBy('status')
            ->get();

        foreach ($statusRows as $row) {
            $key = $row->status instanceof MemberDueStatus ? $row->status->value : (string) $row->status;
            $statusCounts[$key] = (int) $row->aggregate;
        }

        $collections = $this->sumDecimal(
            $this->paymentsBaseQuery($from, $to, $memberScopeId)->where('status', PaymentStatus::Posted),
            'amount',
        );

        $recentPaymentsCount = $this->paymentsBaseQuery($from, $to, $memberScopeId)
            ->where('status', PaymentStatus::Posted)
            ->count();

        $collectionRate = Money::isZero($expected)
            ? '0.00'
            : bcadd(bcmul(bcdiv($collections, $expected, 6), '100', 4), '0', 2);

        $currentMonthStart = now()->startOfMonth()->toDateString();
        $currentMonthEnd = now()->endOfMonth()->toDateString();
        $previousMonthStart = now()->subMonthNoOverflow()->startOfMonth()->toDateString();
        $previousMonthEnd = now()->subMonthNoOverflow()->endOfMonth()->toDateString();

        $currentMonth = $this->periodSnapshot($currentMonthStart, $currentMonthEnd, $memberScopeId);
        $previousMonth = $this->periodSnapshot($previousMonthStart, $previousMonthEnd, $memberScopeId);

        $recentPayments = $this->paymentsBaseQuery($from, $to, $memberScopeId)
            ->with(['member'])
            ->latest('received_at')
            ->latest('id')
            ->limit(8)
            ->get()
            ->map(fn (Payment $payment) => [
                'id' => $payment->id,
                'receipt_number' => $payment->receipt_number,
                'amount' => Money::normalize((string) $payment->amount),
                'currency' => $payment->currency,
                'status' => $payment->status?->value,
                'received_at' => $payment->received_at?->toDateTimeString(),
                'member_name' => $payment->member?->name,
                'member_id' => $payment->member?->member_id,
            ])
            ->all();

        return [
            'role' => $forMember ? UserRole::Member->value : 'staff',
            'currency' => 'BDT',
            'filters' => ['from' => $from, 'to' => $to],
            'active_members' => $activeMembers,
            'total_members' => $totalMembers,
            'expected_dues' => $expected,
            'actual_collections' => $collections,
            'allocated_to_dues' => $allocated,
            'outstanding' => $outstanding,
            'collection_rate' => $collectionRate,
            'payment_status' => [
                'pending' => $statusCounts[MemberDueStatus::Pending->value],
                'partial' => $statusCounts[MemberDueStatus::Partial->value],
                'paid' => $statusCounts[MemberDueStatus::Paid->value],
                'voided' => $statusCounts[MemberDueStatus::Voided->value],
            ],
            'recent_payments_count' => $recentPaymentsCount,
            'current_month' => $currentMonth,
            'previous_month' => $previousMonth,
            'recent_payments' => $recentPayments,
        ];
    }

    /**
     * Individual member statement for a selected period.
     *
     * @return array{
     *     member: array{id: int, name: string, member_id: string|null, email: string},
     *     summary: array{
     *         expected_dues: string,
     *         total_paid: string,
     *         allocated_to_dues: string,
     *         outstanding: string,
     *         currency: string,
     *         filters: array{from: string|null, to: string|null},
     *     },
     *     dues: list<array<string, mixed>>,
     *     payments: list<array<string, mixed>>,
     * }
     */
    public function memberStatement(User $member, ?string $from = null, ?string $to = null): array
    {
        [$from, $to] = $this->normalizeDateRange($from, $to);

        $dues = MemberDue::query()
            ->with(['period', 'plan'])
            ->where('user_id', $member->id)
            ->when($from, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('starts_on', '>=', $from)))
            ->when($to, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('ends_on', '<=', $to)))
            ->orderByDesc('id')
            ->get();

        $expected = Money::normalize('0');
        $allocated = Money::normalize('0');
        $dueRows = [];

        foreach ($dues as $due) {
            if ($due->status !== MemberDueStatus::Voided) {
                $expected = Money::add($expected, (string) $due->amount_due);
                $allocated = Money::add($allocated, (string) $due->amount_allocated);
            }

            $dueRows[] = [
                'id' => $due->id,
                'period_label' => $due->period?->label,
                'year' => $due->period?->year,
                'month' => $due->period?->month,
                'plan_name' => $due->plan?->name,
                'amount_due' => Money::normalize((string) $due->amount_due),
                'amount_allocated' => Money::normalize((string) $due->amount_allocated),
                'outstanding' => $due->outstandingBalance(),
                'status' => $due->status?->value,
            ];
        }

        $payments = Payment::query()
            ->with(['allocations.memberDue.period'])
            ->where('user_id', $member->id)
            ->when($from, fn (Builder $q) => $q->whereDate('received_at', '>=', $from))
            ->when($to, fn (Builder $q) => $q->whereDate('received_at', '<=', $to))
            ->latest('received_at')
            ->get();

        $totalPaid = Money::normalize('0');
        $paymentRows = [];

        foreach ($payments as $payment) {
            if ($payment->status === PaymentStatus::Posted) {
                $totalPaid = Money::add($totalPaid, (string) $payment->amount);
            }

            $paymentRows[] = [
                'id' => $payment->id,
                'receipt_number' => $payment->receipt_number,
                'amount' => Money::normalize((string) $payment->amount),
                'method' => $payment->method?->value,
                'status' => $payment->status?->value,
                'received_at' => $payment->received_at?->toDateTimeString(),
                'reversed_at' => $payment->reversed_at?->toDateTimeString(),
                'reversal_reason' => $payment->reversal_reason,
                'allocations' => $payment->allocations->map(fn ($allocation) => [
                    'amount' => Money::normalize((string) $allocation->amount),
                    'is_reversed' => (bool) $allocation->is_reversed,
                    'period_label' => $allocation->memberDue?->period?->label,
                ])->all(),
            ];
        }

        return [
            'member' => [
                'id' => $member->id,
                'name' => $member->name,
                'member_id' => $member->member_id,
                'email' => $member->email,
            ],
            'summary' => [
                'expected_dues' => $expected,
                'total_paid' => $totalPaid,
                'allocated_to_dues' => $allocated,
                'outstanding' => Money::sub($expected, $allocated),
                'currency' => 'BDT',
                'filters' => ['from' => $from, 'to' => $to],
            ],
            'dues' => $dueRows,
            'payments' => $paymentRows,
        ];
    }

    /**
     * Member-wise report with server-side page rows + grand totals for the filter.
     *
     * @return array{
     *     rows: LengthAwarePaginator,
     *     summary: array{
     *         expected_dues: string,
     *         allocated_to_dues: string,
     *         outstanding: string,
     *         actual_collections: string,
     *         active_members: int,
     *         currency: string,
     *         filters: array{from: string|null, to: string|null, search: string|null},
     *     }
     * }
     */
    public function memberWiseReport(
        ?string $from = null,
        ?string $to = null,
        ?string $search = null,
        int $perPage = 15,
    ): array {
        [$from, $to] = $this->normalizeDateRange($from, $to);

        $membersQuery = User::query()
            ->where('role', UserRole::Member)
            ->when(filled($search), function (Builder $query) use ($search) {
                $term = '%'.$search.'%';
                $query->where(function (Builder $builder) use ($term) {
                    $builder->where('name', 'like', $term)
                        ->orWhere('email', 'like', $term)
                        ->orWhere('member_id', 'like', $term);
                });
            })
            ->orderBy('name');

        $memberIds = (clone $membersQuery)->pluck('id');

        $duesAgg = MemberDue::query()
            ->selectRaw('user_id')
            ->selectRaw('COALESCE(SUM(CASE WHEN status != ? THEN amount_due ELSE 0 END), 0) as expected_dues', [MemberDueStatus::Voided->value])
            ->selectRaw('COALESCE(SUM(CASE WHEN status != ? THEN amount_allocated ELSE 0 END), 0) as allocated_to_dues', [MemberDueStatus::Voided->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as pending_count', [MemberDueStatus::Pending->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as partial_count', [MemberDueStatus::Partial->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as paid_count', [MemberDueStatus::Paid->value])
            ->whereIn('user_id', $memberIds)
            ->when($from, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('starts_on', '>=', $from)))
            ->when($to, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('ends_on', '<=', $to)))
            ->groupBy('user_id')
            ->get()
            ->keyBy('user_id');

        $paymentsAgg = Payment::query()
            ->selectRaw('user_id, COALESCE(SUM(amount), 0) as collections')
            ->where('status', PaymentStatus::Posted)
            ->whereIn('user_id', $memberIds)
            ->when($from, fn (Builder $q) => $q->whereDate('received_at', '>=', $from))
            ->when($to, fn (Builder $q) => $q->whereDate('received_at', '<=', $to))
            ->groupBy('user_id')
            ->pluck('collections', 'user_id');

        $paginator = $membersQuery->paginate($perPage)->withQueryString();

        $paginator->setCollection(
            $paginator->getCollection()->map(function (User $member) use ($duesAgg, $paymentsAgg) {
                $due = $duesAgg->get($member->id);
                $expected = Money::normalize((string) ($due->expected_dues ?? '0'));
                $allocated = Money::normalize((string) ($due->allocated_to_dues ?? '0'));
                $collections = Money::normalize((string) ($paymentsAgg[$member->id] ?? '0'));

                return [
                    'user_id' => $member->id,
                    'member_id' => $member->member_id,
                    'name' => $member->name,
                    'email' => $member->email,
                    'is_active' => $member->is_active,
                    'expected_dues' => $expected,
                    'allocated_to_dues' => $allocated,
                    'outstanding' => Money::sub($expected, $allocated),
                    'actual_collections' => $collections,
                    'payment_status' => [
                        'pending' => (int) ($due->pending_count ?? 0),
                        'partial' => (int) ($due->partial_count ?? 0),
                        'paid' => (int) ($due->paid_count ?? 0),
                    ],
                ];
            })
        );

        $summaryExpected = Money::normalize('0');
        $summaryAllocated = Money::normalize('0');
        $summaryCollections = Money::normalize('0');
        foreach ($duesAgg as $row) {
            $summaryExpected = Money::add($summaryExpected, (string) $row->expected_dues);
            $summaryAllocated = Money::add($summaryAllocated, (string) $row->allocated_to_dues);
        }
        foreach ($paymentsAgg as $amount) {
            $summaryCollections = Money::add($summaryCollections, (string) $amount);
        }

        return [
            'rows' => $paginator,
            'summary' => [
                'expected_dues' => $summaryExpected,
                'allocated_to_dues' => $summaryAllocated,
                'outstanding' => Money::sub($summaryExpected, $summaryAllocated),
                'actual_collections' => $summaryCollections,
                'active_members' => User::query()
                    ->where('role', UserRole::Member)
                    ->where('is_active', true)
                    ->when(filled($search), function (Builder $query) use ($search) {
                        $term = '%'.$search.'%';
                        $query->where(function (Builder $builder) use ($term) {
                            $builder->where('name', 'like', $term)
                                ->orWhere('email', 'like', $term)
                                ->orWhere('member_id', 'like', $term);
                        });
                    })
                    ->count(),
                'currency' => 'BDT',
                'filters' => ['from' => $from, 'to' => $to, 'search' => $search],
            ],
        ];
    }

    /**
     * Month-wise report keyed by due period.
     *
     * @return array{
     *     rows: LengthAwarePaginator,
     *     summary: array{
     *         expected_dues: string,
     *         allocated_to_dues: string,
     *         outstanding: string,
     *         actual_collections: string,
     *         currency: string,
     *         filters: array{from: string|null, to: string|null},
     *     }
     * }
     */
    public function monthWiseReport(
        ?string $from = null,
        ?string $to = null,
        int $perPage = 15,
    ): array {
        [$from, $to] = $this->normalizeDateRange($from, $to);

        $periodsQuery = DuePeriod::query()
            ->when($from, fn (Builder $q) => $q->whereDate('starts_on', '>=', $from))
            ->when($to, fn (Builder $q) => $q->whereDate('ends_on', '<=', $to))
            ->orderByDesc('year')
            ->orderByDesc('month');

        $periodIds = (clone $periodsQuery)->pluck('id');

        $duesAgg = MemberDue::query()
            ->selectRaw('due_period_id')
            ->selectRaw('COALESCE(SUM(CASE WHEN status != ? THEN amount_due ELSE 0 END), 0) as expected_dues', [MemberDueStatus::Voided->value])
            ->selectRaw('COALESCE(SUM(CASE WHEN status != ? THEN amount_allocated ELSE 0 END), 0) as allocated_to_dues', [MemberDueStatus::Voided->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as pending_count', [MemberDueStatus::Pending->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as partial_count', [MemberDueStatus::Partial->value])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as paid_count', [MemberDueStatus::Paid->value])
            ->whereIn('due_period_id', $periodIds)
            ->groupBy('due_period_id')
            ->get()
            ->keyBy('due_period_id');

        // Collections attributed to months by payment received_at falling in period date range.
        $collectionsByPeriod = collect();
        foreach (DuePeriod::query()->whereIn('id', $periodIds)->get() as $period) {
            $amount = $this->sumDecimal(
                Payment::query()
                    ->where('status', PaymentStatus::Posted)
                    ->whereDate('received_at', '>=', $period->starts_on->toDateString())
                    ->whereDate('received_at', '<=', $period->ends_on->toDateString()),
                'amount',
            );
            $collectionsByPeriod[$period->id] = $amount;
        }

        $paginator = $periodsQuery->paginate($perPage)->withQueryString();
        $paginator->setCollection(
            $paginator->getCollection()->map(function (DuePeriod $period) use ($duesAgg, $collectionsByPeriod) {
                $due = $duesAgg->get($period->id);
                $expected = Money::normalize((string) ($due->expected_dues ?? '0'));
                $allocated = Money::normalize((string) ($due->allocated_to_dues ?? '0'));
                $collections = Money::normalize((string) ($collectionsByPeriod[$period->id] ?? '0'));

                return [
                    'due_period_id' => $period->id,
                    'label' => $period->label,
                    'year' => $period->year,
                    'month' => $period->month,
                    'starts_on' => $period->starts_on->toDateString(),
                    'ends_on' => $period->ends_on->toDateString(),
                    'expected_dues' => $expected,
                    'allocated_to_dues' => $allocated,
                    'outstanding' => Money::sub($expected, $allocated),
                    'actual_collections' => $collections,
                    'payment_status' => [
                        'pending' => (int) ($due->pending_count ?? 0),
                        'partial' => (int) ($due->partial_count ?? 0),
                        'paid' => (int) ($due->paid_count ?? 0),
                    ],
                ];
            })
        );

        $summaryExpected = Money::normalize('0');
        $summaryAllocated = Money::normalize('0');
        $summaryCollections = Money::normalize('0');
        foreach ($duesAgg as $row) {
            $summaryExpected = Money::add($summaryExpected, (string) $row->expected_dues);
            $summaryAllocated = Money::add($summaryAllocated, (string) $row->allocated_to_dues);
        }
        foreach ($collectionsByPeriod as $amount) {
            $summaryCollections = Money::add($summaryCollections, (string) $amount);
        }

        return [
            'rows' => $paginator,
            'summary' => [
                'expected_dues' => $summaryExpected,
                'allocated_to_dues' => $summaryAllocated,
                'outstanding' => Money::sub($summaryExpected, $summaryAllocated),
                'actual_collections' => $summaryCollections,
                'currency' => 'BDT',
                'filters' => ['from' => $from, 'to' => $to],
            ],
        ];
    }

    /**
     * Rows for PDF/print export (capped for association scale ~3000).
     *
     * @return array{rows: Collection<int, array<string, mixed>>, summary: array<string, mixed>}
     */
    public function memberWiseExport(?string $from = null, ?string $to = null, ?string $search = null, int $limit = 3000): array
    {
        $report = $this->memberWiseReport($from, $to, $search, perPage: max(1, min($limit, 3000)));

        return [
            'rows' => collect($report['rows']->items()),
            'summary' => $report['summary'],
        ];
    }

    /**
     * @return array{rows: Collection<int, array<string, mixed>>, summary: array<string, mixed>}
     */
    public function monthWiseExport(?string $from = null, ?string $to = null, int $limit = 120): array
    {
        $report = $this->monthWiseReport($from, $to, perPage: max(1, min($limit, 120)));

        return [
            'rows' => collect($report['rows']->items()),
            'summary' => $report['summary'],
        ];
    }

    /**
     * @return array{0: string|null, 1: string|null}
     */
    private function normalizeDateRange(?string $from, ?string $to): array
    {
        $from = filled($from) ? $from : null;
        $to = filled($to) ? $to : null;

        return [$from, $to];
    }

    private function duesBaseQuery(?string $from, ?string $to, ?int $memberId = null): Builder
    {
        return MemberDue::query()
            ->when($memberId, fn (Builder $q) => $q->where('user_id', $memberId))
            ->when($from, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('starts_on', '>=', $from)))
            ->when($to, fn (Builder $q) => $q->whereHas('period', fn (Builder $p) => $p->whereDate('ends_on', '<=', $to)));
    }

    private function paymentsBaseQuery(?string $from, ?string $to, ?int $memberId = null): Builder
    {
        return Payment::query()
            ->when($memberId, fn (Builder $q) => $q->where('user_id', $memberId))
            ->when($from, fn (Builder $q) => $q->whereDate('received_at', '>=', $from))
            ->when($to, fn (Builder $q) => $q->whereDate('received_at', '<=', $to));
    }

    private function sumDecimal(Builder $query, string $column): string
    {
        $value = $query->sum($column);

        return Money::normalize($value === null ? '0' : (string) $value);
    }

    /**
     * @return array{
     *     label: string,
     *     from: string,
     *     to: string,
     *     expected_dues: string,
     *     actual_collections: string,
     *     outstanding: string,
     * }
     */
    private function periodSnapshot(string $from, string $to, ?int $memberId = null): array
    {
        $expected = $this->sumDecimal(
            $this->duesBaseQuery($from, $to, $memberId)->where('status', '!=', MemberDueStatus::Voided),
            'amount_due',
        );
        $allocated = $this->sumDecimal(
            $this->duesBaseQuery($from, $to, $memberId)->where('status', '!=', MemberDueStatus::Voided),
            'amount_allocated',
        );
        $collections = $this->sumDecimal(
            $this->paymentsBaseQuery($from, $to, $memberId)->where('status', PaymentStatus::Posted),
            'amount',
        );

        return [
            'label' => $from.' → '.$to,
            'from' => $from,
            'to' => $to,
            'expected_dues' => $expected,
            'actual_collections' => $collections,
            'outstanding' => Money::sub($expected, $allocated),
        ];
    }
}
