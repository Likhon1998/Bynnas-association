<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreNoticeRequest;
use App\Http\Requests\Api\V1\UpdateNoticeRequest;
use App\Http\Resources\Api\V1\NoticeResource;
use App\Models\Notice;
use App\Models\User;
use App\Policies\NoticePolicy;
use App\Services\Notices\NoticeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Throwable;

class NoticeController extends Controller
{
    public function __construct(
        private readonly NoticeService $notices,
        private readonly NoticePolicy $policy,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        /** @var User $actor */
        $actor = $request->user();
        abort_unless($this->policy->viewAny($actor), 403);

        if ($actor->isMember()) {
            return NoticeResource::collection(
                $this->notices->paginateForMember(
                    $actor,
                    min(max((int) $request->integer('per_page', 15), 1), 100),
                )
            );
        }

        return NoticeResource::collection(
            $this->notices->paginateForStaff(
                status: $request->string('status')->toString() ?: null,
                perPage: min(max((int) $request->integer('per_page', 15), 1), 100),
            )
        );
    }

    public function store(StoreNoticeRequest $request): JsonResponse
    {
        try {
            $notice = $this->notices->create($request->user(), $request->validated());
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => new NoticeResource($notice->load('targets')),
            'message' => 'Notice drafted.',
        ], 201);
    }

    public function show(Request $request, Notice $notice): NoticeResource
    {
        abort_unless($this->policy->view($request->user(), $notice), 403);

        if ($request->user()->isStaff()) {
            $notice->loadMissing('targets');
        }

        return new NoticeResource($notice);
    }

    public function update(UpdateNoticeRequest $request, Notice $notice): NoticeResource|JsonResponse
    {
        try {
            $updated = $this->notices->update($request->user(), $notice, $request->validated());
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return new NoticeResource($updated);
    }

    public function preview(Request $request, Notice $notice): JsonResponse
    {
        abort_unless($this->policy->publish($request->user(), $notice), 403);

        $preview = $this->notices->preview($notice);

        return response()->json([
            'data' => [
                'notice' => new NoticeResource($preview['notice']->load('targets')),
                'recipient_count' => $preview['recipient_count'],
                'sample_member_ids' => $preview['sample_member_ids'],
            ],
        ]);
    }

    public function publish(Request $request, Notice $notice): JsonResponse
    {
        abort_unless($this->policy->publish($request->user(), $notice), 403);

        try {
            $published = $this->notices->publish($request->user(), $notice);
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => new NoticeResource($published),
            'message' => 'Notice published. Delivery queued in chunks.',
        ]);
    }

    public function archive(Request $request, Notice $notice): NoticeResource
    {
        abort_unless($this->policy->archive($request->user(), $notice), 403);

        return new NoticeResource($this->notices->archive($request->user(), $notice));
    }
}
