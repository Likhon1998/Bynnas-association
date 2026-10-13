<?php

namespace App\Services\Notifications;

use App\Contracts\PushNotificationSender;
use App\Enums\AppNotificationType;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    public function __construct(
        private readonly PushNotificationSender $push,
    ) {}

    /**
     * Create an in-app notification idempotently (safe under job retries).
     *
     * @param  array<string, mixed>|null  $data
     */
    public function notify(
        User $user,
        AppNotificationType $type,
        string $title,
        string $body,
        string $dedupeKey,
        ?array $data = null,
        bool $sendPush = true,
    ): UserNotification {
        try {
            $notification = UserNotification::query()->firstOrCreate(
                [
                    'user_id' => $user->id,
                    'dedupe_key' => $dedupeKey,
                ],
                [
                    'type' => $type,
                    'title' => $title,
                    'body' => $body,
                    'data' => $data,
                ],
            );
        } catch (QueryException $e) {
            // Concurrent insert race on unique key — fetch existing.
            Log::debug('Notification dedupe race resolved', ['dedupe_key' => $dedupeKey]);
            $notification = UserNotification::query()
                ->where('user_id', $user->id)
                ->where('dedupe_key', $dedupeKey)
                ->firstOrFail();
        }

        if ($sendPush && $notification->wasRecentlyCreated) {
            $this->push->sendToUser($user->id, $notification);
        }

        return $notification;
    }

    public function paginateForUser(User $user, int $perPage = 20): LengthAwarePaginator
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->latest('id')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function unreadCount(User $user): int
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();
    }

    public function markRead(User $user, UserNotification $notification): UserNotification
    {
        abort_unless($notification->user_id === $user->id, 403);

        if ($notification->read_at === null) {
            $notification->forceFill(['read_at' => now()])->save();
        }

        return $notification->refresh();
    }

    public function markAllRead(User $user): int
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }
}
