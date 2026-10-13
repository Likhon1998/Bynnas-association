<?php

namespace App\Contracts;

use App\Models\UserNotification;

interface PushNotificationSender
{
    /**
     * Attempt to deliver a push for an in-app notification to the user's active device tokens.
     * Implementations must be safe to retry and must not throw for missing credentials.
     *
     * @return array{attempted: int, sent: int, skipped: int, invalidated: int}
     */
    public function sendToUser(int $userId, UserNotification $notification): array;

    public function isConfigured(): bool;
}
