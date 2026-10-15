<?php

namespace App\Contracts;

interface SmsGateway
{
    /**
     * @return array{success: bool, provider_message_id: string|null, error: string|null}
     */
    public function send(string $phone, string $body): array;

    public function isConfigured(): bool;
}
