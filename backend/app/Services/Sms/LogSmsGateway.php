<?php

namespace App\Services\Sms;

use App\Contracts\SmsGateway;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Development / fallback SMS gateway. Logs messages instead of sending.
 * Replace with a real provider when SMS_GATEWAY_URL + credentials are set.
 */
class LogSmsGateway implements SmsGateway
{
    public function isConfigured(): bool
    {
        return true;
    }

    public function send(string $phone, string $body): array
    {
        $id = 'log-'.Str::uuid()->toString();
        Log::info('SMS queued (log gateway)', [
            'phone' => $phone,
            'body' => $body,
            'provider_message_id' => $id,
        ]);

        return [
            'success' => true,
            'provider_message_id' => $id,
            'error' => null,
        ];
    }
}
