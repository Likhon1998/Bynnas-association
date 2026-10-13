<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\ReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StatementController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly FinancePolicy $policy,
    ) {}

    public function me(Request $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();
        abort_unless($actor->isMember(), 403);

        return $this->respond($actor, $request);
    }

    public function show(Request $request, User $member): JsonResponse
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $member), 403);

        return $this->respond($member, $request);
    }

    private function respond(User $member, Request $request): JsonResponse
    {
        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;

        return response()->json([
            'data' => $this->reports->memberStatement($member, $from, $to),
        ]);
    }
}
