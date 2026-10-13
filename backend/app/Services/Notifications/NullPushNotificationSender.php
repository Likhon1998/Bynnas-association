<?php

namespace App\Services\Notifications;

use App\Contracts\PushNotificationSender;
use App\Models\UserNotification;
use Illuminate\Support\Facades\Log;

/**
 * Default push sender when Firebase credentials are not configured.
 * Logs intent only — does not claim real delivery.
 */
class NullPushNotificationSender implements PushNotificationSender
{
    public function sendToUser(int $userId, UserNotification $notification): array
    {
        Log::debug('Push skipped (FCM not configured)', [
            'user_id' => $userId,
            'notification_id' => $notification->id,
            'type' => $notification->type?->value,
        ]);

        return [
            'attempted' => 0,
            'sent' => 0,
            'skipped' => 1,
            'invalidated' => 0,
        ];
    }

    public function isConfigured(): bool
    {
        return false;
    }
}
