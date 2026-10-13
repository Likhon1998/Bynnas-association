<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserNotificationResource;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\Notifications\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notifications,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        /** @var User $user */
        $user = $request->user();

        return UserNotificationResource::collection(
            $this->notifications->paginateForUser(
                $user,
                min(max((int) $request->integer('per_page', 20), 1), 100),
            )
        );
    }

    public function unreadCount(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'data' => [
                'unread_count' => $this->notifications->unreadCount($user),
            ],
        ]);
    }

    public function markRead(Request $request, UserNotification $notification): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'data' => (new UserNotificationResource(
                $this->notifications->markRead($user, $notification)
            ))->resolve(),
        ]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $updated = $this->notifications->markAllRead($user);

        return response()->json([
            'data' => [
                'marked_read' => $updated,
                'unread_count' => 0,
            ],
            'message' => 'All notifications marked as read.',
        ]);
    }
}
