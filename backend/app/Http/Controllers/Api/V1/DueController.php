<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\GenerateDuesRequest;
use App\Http\Requests\Api\V1\VoidDueRequest;
use App\Http\Resources\Api\V1\MemberDueResource;
use App\Models\MemberDue;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\BalanceService;
use App\Services\Finance\DueService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Throwable;

class DueController extends Controller
{
    public function __construct(
        private readonly DueService $dues,
        private readonly BalanceService $balances,
        private readonly FinancePolicy $policy,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        /** @var User $actor */
        $actor = $request->user();

        if ($actor->isMember()) {
            return MemberDueResource::collection(
                $this->dues->paginateForMember(
                    $actor,
                    min(max((int) $request->integer('per_page', 15), 1), 100),
                )
            );
        }

        abort_unless($this->policy->viewAnyFinancial($actor), 403);

        return MemberDueResource::collection(
            $this->dues->paginateAll(
                userId: $request->filled('user_id') ? (int) $request->integer('user_id') : null,
                status: $request->string('status')->toString() ?: null,
                perPage: min(max((int) $request->integer('per_page', 15), 1), 100),
            )
        );
    }

    public function generate(GenerateDuesRequest $request): JsonResponse
    {
        $data = $request->validated();

        $result = $this->dues->generateForPeriod(
            actor: $request->user(),
            year: (int) $data['year'],
            month: (int) $data['month'],
            contributionPlanId: isset($data['contribution_plan_id']) ? (int) $data['contribution_plan_id'] : null,
            memberUserId: isset($data['user_id']) ? (int) $data['user_id'] : null,
        );

        return response()->json([
            'data' => [
                'period' => [
                    'id' => $result['period']->id,
                    'label' => $result['period']->label,
                    'year' => $result['period']->year,
                    'month' => $result['period']->month,
                ],
                'created' => $result['created'],
                'reused' => $result['reused'],
                'dues' => MemberDueResource::collection(collect($result['dues'])->each->load(['period', 'plan'])),
            ],
            'message' => 'Dues generation completed.',
        ], 201);
    }

    public function void(VoidDueRequest $request, MemberDue $due): MemberDueResource|JsonResponse
    {
        try {
            $voided = $this->dues->voidDue($request->user(), $due, $request->validated('reason'));
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return new MemberDueResource($voided->load(['period', 'plan']));
    }

    public function myBalance(Request $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();
        abort_unless($actor->isMember(), 403);

        return response()->json([
            'data' => $this->balances->outstandingForMember($actor),
        ]);
    }

    public function balance(Request $request, User $member): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        if (! $member->isMember()) {
            abort(404);
        }

        abort_unless($this->policy->viewMemberFinancial($actor, $member), 403);

        return response()->json([
            'data' => $this->balances->outstandingForMember($member),
        ]);
    }
}
