<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreContributionAssignmentRequest;
use App\Http\Requests\Api\V1\StoreContributionPlanRequest;
use App\Http\Requests\Api\V1\UpdateContributionPlanRequest;
use App\Http\Resources\Api\V1\ContributionAssignmentResource;
use App\Http\Resources\Api\V1\ContributionPlanResource;
use App\Models\ContributionPlan;
use App\Policies\FinancePolicy;
use App\Services\Finance\ContributionPlanService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ContributionPlanController extends Controller
{
    public function __construct(
        private readonly ContributionPlanService $plans,
        private readonly FinancePolicy $policy,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        abort_unless($this->policy->viewAnyFinancial($request->user()), 403);

        $active = $request->has('active')
            ? filter_var($request->query('active'), FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            : null;

        return ContributionPlanResource::collection(
            $this->plans->paginatePlans(
                activeOnly: $active,
                perPage: min(max((int) $request->integer('per_page', 15), 1), 100),
            )
        );
    }

    public function store(StoreContributionPlanRequest $request): JsonResponse
    {
        $plan = $this->plans->createPlan($request->user(), $request->validated());

        return response()->json([
            'data' => new ContributionPlanResource($plan),
            'message' => 'Contribution plan created.',
        ], 201);
    }

    public function show(Request $request, ContributionPlan $contributionPlan): ContributionPlanResource
    {
        abort_unless($this->policy->viewAnyFinancial($request->user()), 403);

        return new ContributionPlanResource($contributionPlan);
    }

    public function update(UpdateContributionPlanRequest $request, ContributionPlan $contributionPlan): ContributionPlanResource
    {
        $plan = $this->plans->updatePlan($request->user(), $contributionPlan, $request->validated());

        return new ContributionPlanResource($plan);
    }

    public function assign(StoreContributionAssignmentRequest $request): JsonResponse
    {
        $assignment = $this->plans->assign($request->user(), $request->validated());

        return response()->json([
            'data' => new ContributionAssignmentResource($assignment),
            'message' => 'Contribution assignment created.',
        ], 201);
    }
}
