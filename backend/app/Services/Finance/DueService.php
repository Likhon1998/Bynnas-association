<?php

namespace App\Services\Finance;

use App\Enums\MemberDueStatus;
use App\Enums\UserRole;
use App\Models\ContributionPlan;
use App\Models\DuePeriod;
use App\Models\MemberDue;
use App\Models\User;
use App\Support\Money;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use LogicException;

class DueService
{
    public function __construct(
        private readonly ContributionPlanService $plans,
        private readonly FinancialAuditLogger $audit,
    ) {}

    public function findOrCreatePeriod(int $year, int $month): DuePeriod
    {
        if ($month < 1 || $month > 12) {
            throw new InvalidArgumentException('Month must be between 1 and 12.');
        }

        $starts = Carbon::create($year, $month, 1)->startOfDay();
        $ends = $starts->copy()->endOfMonth()->startOfDay();
        $label = sprintf('%04d-%02d', $year, $month);

        return DuePeriod::query()->firstOrCreate(
            ['year' => $year, 'month' => $month],
            [
                'label' => $label,
                'starts_on' => $starts->toDateString(),
                'ends_on' => $ends->toDateString(),
            ],
        );
    }

    /**
     * Generate dues for active members for a plan in a period.
     *
     * @return array{period: DuePeriod, created: int, reused: int, dues: list<MemberDue>}
     */
    public function generateForPeriod(
        User $actor,
        int $year,
        int $month,
        ?int $contributionPlanId = null,
        ?int $memberUserId = null,
    ): array {
        return DB::transaction(function () use ($actor, $year, $month, $contributionPlanId, $memberUserId) {
            $period = $this->findOrCreatePeriod($year, $month);
            $onDate = $period->starts_on->toDateString();

            $plansQuery = ContributionPlan::query()->where('is_active', true);
            if ($contributionPlanId !== null) {
                $plansQuery->whereKey($contributionPlanId);
            }
            $plans = $plansQuery->lockForUpdate()->get();

            if ($plans->isEmpty()) {
                throw new InvalidArgumentException('No active contribution plans found.');
            }

            $membersQuery = User::query()
                ->where('role', UserRole::Member)
                ->where('is_active', true);
            if ($memberUserId !== null) {
                $membersQuery->whereKey($memberUserId);
            }
            $members = $membersQuery->lockForUpdate()->get();

            $created = 0;
            $reused = 0;
            $dues = [];

            foreach ($members as $member) {
                foreach ($plans as $plan) {
                    $idempotencyKey = sprintf(
                        'due:%d:%d:%d',
                        $member->id,
                        $period->id,
                        $plan->id,
                    );

                    $existing = MemberDue::query()
                        ->where('idempotency_key', $idempotencyKey)
                        ->lockForUpdate()
                        ->first();

                    if ($existing !== null) {
                        $reused++;
                        $dues[] = $existing;

                        continue;
                    }

                    $amount = $this->plans->resolveAmount($member, $plan, $onDate);

                    $due = MemberDue::query()->create([
                        'user_id' => $member->id,
                        'due_period_id' => $period->id,
                        'contribution_plan_id' => $plan->id,
                        'amount_due' => $amount,
                        'amount_allocated' => Money::normalize('0'),
                        'status' => MemberDueStatus::Pending,
                        'currency' => $plan->currency,
                        'idempotency_key' => $idempotencyKey,
                    ]);

                    $this->audit->log($actor, 'member_due.generated', $due, null, $due->toArray(), [
                        'period' => $period->label,
                        'plan_code' => $plan->code,
                    ]);

                    $created++;
                    $dues[] = $due;
                }
            }

            return [
                'period' => $period,
                'created' => $created,
                'reused' => $reused,
                'dues' => $dues,
            ];
        });
    }

    public function voidDue(User $actor, MemberDue $due, string $reason): MemberDue
    {
        return DB::transaction(function () use ($actor, $due, $reason) {
            $due = MemberDue::query()->whereKey($due->id)->lockForUpdate()->firstOrFail();

            if ($due->status === MemberDueStatus::Voided) {
                throw new LogicException('Due is already voided.');
            }

            if (Money::isPositive((string) $due->amount_allocated)) {
                throw new LogicException('Cannot void a due with allocations. Reverse payments first.');
            }

            $before = $due->toArray();
            $due->forceFill([
                'status' => MemberDueStatus::Voided,
                'voided_at' => now(),
                'voided_by' => $actor->id,
                'void_reason' => $reason,
            ])->save();

            $this->audit->log($actor, 'member_due.voided', $due, $before, $due->fresh()->toArray(), [
                'reason' => $reason,
            ]);

            return $due->refresh();
        });
    }

    public function paginateForMember(User $member, int $perPage = 15): LengthAwarePaginator
    {
        return MemberDue::query()
            ->with(['period', 'plan'])
            ->where('user_id', $member->id)
            ->latest('id')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function paginateAll(?int $userId = null, ?string $status = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = MemberDue::query()->with(['period', 'plan', 'member'])->latest('id');

        if ($userId !== null) {
            $query->where('user_id', $userId);
        }

        if (filled($status)) {
            $query->where('status', $status);
        }

        return $query->paginate($perPage)->withQueryString();
    }
}
