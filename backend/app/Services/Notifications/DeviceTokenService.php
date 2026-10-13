<?php

namespace App\Services\Notifications;

use App\Enums\DevicePlatform;
use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class DeviceTokenService
{
    /**
     * @param  array{token: string, platform: string, device_name?: string|null}  $data
     */
    public function register(User $user, array $data): DeviceToken
    {
        return DB::transaction(function () use ($user, $data) {
            $existing = DeviceToken::query()
                ->where('token', $data['token'])
                ->lockForUpdate()
                ->first();

            if ($existing !== null) {
                $existing->forceFill([
                    'user_id' => $user->id,
                    'platform' => DevicePlatform::from($data['platform']),
                    'device_name' => $data['device_name'] ?? $existing->device_name,
                    'last_used_at' => now(),
                    'invalidated_at' => null,
                ])->save();

                return $existing->refresh();
            }

            return DeviceToken::query()->create([
                'user_id' => $user->id,
                'token' => $data['token'],
                'platform' => DevicePlatform::from($data['platform']),
                'device_name' => $data['device_name'] ?? null,
                'last_used_at' => now(),
            ]);
        });
    }

    public function invalidate(User $user, string $token): void
    {
        DeviceToken::query()
            ->where('user_id', $user->id)
            ->where('token', $token)
            ->whereNull('invalidated_at')
            ->update(['invalidated_at' => now()]);
    }
}
