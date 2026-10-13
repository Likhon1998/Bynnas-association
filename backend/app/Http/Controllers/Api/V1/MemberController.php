<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreMemberRequest;
use App\Http\Requests\Api\V1\UpdateMemberRequest;
use App\Http\Resources\Api\V1\MemberResource;
use App\Models\User;
use App\Policies\MemberPolicy;
use App\Services\MemberService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MemberController extends Controller
{
    public function __construct(
        private readonly MemberService $members,
        private readonly MemberPolicy $policy,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        abort_unless($this->policy->viewAny($request->user()), 403);

        $paginator = $this->members->paginate(
            search: $request->string('search')->toString() ?: null,
            status: $request->string('status')->toString() ?: null,
            perPage: min(max((int) $request->integer('per_page', 15), 1), 100),
        );

        return MemberResource::collection($paginator);
    }

    public function store(StoreMemberRequest $request): JsonResponse
    {
        $result = $this->members->create($request->validated());

        return response()->json([
            'data' => new MemberResource($result['member']),
            'temporary_password' => $result['temporary_password'],
            'message' => 'Member created successfully.',
        ], 201);
    }

    public function show(Request $request, User $member): MemberResource
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->view($request->user(), $member), 403);

        $member->loadMissing('memberProfile');

        return new MemberResource($member);
    }

    public function me(Request $request): MemberResource
    {
        /** @var User $user */
        $user = $request->user();
        abort_unless($user->isMember(), 403);

        $user->loadMissing('memberProfile');

        return new MemberResource($user);
    }

    public function update(UpdateMemberRequest $request, User $member): MemberResource
    {
        abort_unless($member->isMember(), 404);

        $updated = $this->members->update($member, $request->validated());

        return new MemberResource($updated);
    }

    public function deactivate(Request $request, User $member): MemberResource
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->deactivate($request->user(), $member), 403);

        return new MemberResource($this->members->deactivate($member));
    }

    public function reactivate(Request $request, User $member): MemberResource
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->reactivate($request->user(), $member), 403);

        return new MemberResource($this->members->reactivate($member));
    }
}
