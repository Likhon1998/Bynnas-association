<?php

namespace App\Services\Finance;

use App\Models\ContributionPlan;
use App\Models\MemberContributionAssignment;
use App\Models\User;
use App\Support\Money;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ContributionPlanService
{
    public function __construct(
        private readonly FinancialAuditLogger $audit,
    ) {}

    /**
     * @param  array{
     *     name: string,
     *     code: string,
     *     description?: string|null,
     *     default_amount: string|int,
     *     currency?: string,
     *     is_active?: bool,
     * }  $data
     */
    public function createPlan(User $actor, array $data): ContributionPlan
    {
        return DB::transaction(function () use ($actor, $data) {
            $plan = ContributionPlan::query()->create([
                'name' => $data['name'],
                'code' => strtoupper($data['code']),
                'description' => $data['description'] ?? null,
                'default_amount' => Money::normalize($data['default_amount']),
                'currency' => $data['currency'] ?? 'BDT',
                'is_active' => $data['is_active'] ?? true,
            ]);

            $this->audit->log($actor, 'contribution_plan.created', $plan, null, $plan->toArray());

            return $plan;
        });
    }

    /**
     * @param  array{
     *     name?: string,
     *     description?: string|null,
     *     default_amount?: string|int,
     *     currency?: string,
     *     is_active?: bool,
     * }  $data
     */
    public function updatePlan(User $actor, ContributionPlan $plan, array $data): ContributionPlan
    {
        return DB::transaction(function () use ($actor, $plan, $data) {
            $before = $plan->toArray();

            if (array_key_exists('name', $data)) {
                $plan->name = $data['name'];
            }
            if (array_key_exists('description', $data)) {
                $plan->description = $data['description'];
            }
            if (array_key_exists('default_amount', $data)) {
                $plan->default_amount = Money::normalize($data['default_amount']);
            }
            if (array_key_exists('currency', $data)) {
                $plan->currency = $data['currency'];
            }
            if (array_key_exists('is_active', $data)) {
                $plan->is_active = (bool) $data['is_active'];
            }

            $plan->save();

            $this->audit->log($actor, 'contribution_plan.updated', $plan, $before, $plan->fresh()->toArray());

            return $plan->refresh();
        });
    }

    public function paginatePlans(?bool $activeOnly = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = ContributionPlan::query()->latest('id');

        if ($activeOnly === true) {
            $query->where('is_active', true);
        } elseif ($activeOnly === false) {
            $query->where('is_active', false);
        }

        return $query->paginate($perPage)->withQueryString();
    }

    /**
     * @param  array{
     *     user_id: int,
     *     contribution_plan_id: int,
     *     amount?: string|int|null,
     *     effective_from: string,
     *     effective_to?: string|null,
     *     is_active?: bool,
     * }  $data
     */
    public function assign(User $actor, array $data): MemberContributionAssignment
    {
        return DB::transaction(function () use ($actor, $data) {
            $member = User::query()->whereKey($data['user_id'])->firstOrFail();
            if (! $member->isMember()) {
                throw new InvalidArgumentException('Assignments can only target member users.');
            }

            $plan = ContributionPlan::query()->whereKey($data['contribution_plan_id'])->firstOrFail();

            $assignment = MemberContributionAssignment::query()->create([
                'user_id' => $member->id,
                'contribution_plan_id' => $plan->id,
                'amount' => array_key_exists('amount', $data) && $data['amount'] !== null
                    ? Money::normalize($data['amount'])
                    : null,
                'effective_from' => $data['effective_from'],
                'effective_to' => $data['effective_to'] ?? null,
                'is_active' => $data['is_active'] ?? true,
            ]);

            $this->audit->log($actor, 'contribution_assignment.created', $assignment, null, $assignment->toArray());

            return $assignment->load(['member', 'plan']);
        });
    }

    /**
     * Resolve amount for a member+plan on a given date (assignment override or plan default).
     */
    public function resolveAmount(User $member, ContributionPlan $plan, string $onDate): string
    {
        $assignment = MemberContributionAssignment::query()
            ->where('user_id', $member->id)
            ->where('contribution_plan_id', $plan->id)
            ->where('is_active', true)
            ->whereDate('effective_from', '<=', $onDate)
            ->where(function ($query) use ($onDate) {
                $query->whereNull('effective_to')
                    ->orWhereDate('effective_to', '>=', $onDate);
            })
            ->orderByDesc('effective_from')
            ->first();

        if ($assignment !== null && $assignment->amount !== null) {
            return Money::normalize((string) $assignment->amount);
        }

        return Money::normalize((string) $plan->default_amount);
    }
}
