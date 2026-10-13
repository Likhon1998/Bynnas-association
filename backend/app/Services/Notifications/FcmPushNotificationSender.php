<?php

namespace App\Services\Notifications;

use App\Contracts\PushNotificationSender;
use App\Models\DeviceToken;
use App\Models\UserNotification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * FCM HTTP v1 style sender scaffold.
 * Requires FIREBASE_PROJECT_ID + FIREBASE_SERVICE_ACCOUNT_JSON (path) or FIREBASE_SERVER_KEY (legacy).
 * Without credentials, behaves like a no-op with logging.
 */
class FcmPushNotificationSender implements PushNotificationSender
{
    public function isConfigured(): bool
    {
        return filled(config('services.fcm.server_key'))
            || (filled(config('services.fcm.project_id')) && filled(config('services.fcm.credentials')));
    }

    public function sendToUser(int $userId, UserNotification $notification): array
    {
        if (! $this->isConfigured()) {
            return app(NullPushNotificationSender::class)->sendToUser($userId, $notification);
        }

        $tokens = DeviceToken::query()
            ->where('user_id', $userId)
            ->whereNull('invalidated_at')
            ->pluck('token');

        $attempted = 0;
        $sent = 0;
        $invalidated = 0;

        foreach ($tokens as $token) {
            $attempted++;
            try {
                $ok = $this->sendLegacyOrLog($token, $notification);
                if ($ok) {
                    $sent++;
                    DeviceToken::query()->where('token', $token)->update(['last_used_at' => now()]);
                }
            } catch (Throwable $e) {
                Log::warning('FCM push failed', [
                    'user_id' => $userId,
                    'error' => $e->getMessage(),
                ]);
                if ($this->shouldInvalidate($e->getMessage())) {
                    DeviceToken::query()->where('token', $token)->update(['invalidated_at' => now()]);
                    $invalidated++;
                }
            }
        }

        return [
            'attempted' => $attempted,
            'sent' => $sent,
            'skipped' => $attempted === 0 ? 1 : 0,
            'invalidated' => $invalidated,
        ];
    }

    private function sendLegacyOrLog(string $token, UserNotification $notification): bool
    {
        $serverKey = config('services.fcm.server_key');

        if (! filled($serverKey)) {
            // HTTP v1 with service account is not fully wired without google/auth dependency.
            // Documented setup: install credentials and replace this path when ready.
            Log::info('FCM HTTP v1 credentials present but legacy server key missing; push not sent', [
                'notification_id' => $notification->id,
            ]);

            return false;
        }

        $response = Http::withToken($serverKey)
            ->acceptJson()
            ->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $token,
                'notification' => [
                    'title' => $notification->title,
                    'body' => $notification->body,
                ],
                'data' => array_merge(
                    ['type' => $notification->type?->value ?? 'notice'],
                    $notification->data ?? [],
                ),
            ]);

        if ($response->failed()) {
            throw new \RuntimeException('FCM HTTP '.$response->status().': '.$response->body());
        }

        return true;
    }

    private function shouldInvalidate(string $message): bool
    {
        $needle = strtolower($message);

        return str_contains($needle, 'notregistered')
            || str_contains($needle, 'invalidregistration')
            || str_contains($needle, 'unregistered');
    }
}
