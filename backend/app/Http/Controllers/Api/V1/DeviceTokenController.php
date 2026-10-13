<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\PushNotificationSender;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\RegisterDeviceTokenRequest;
use App\Services\Notifications\DeviceTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function __construct(
        private readonly DeviceTokenService $tokens,
    ) {}

    public function store(RegisterDeviceTokenRequest $request): JsonResponse
    {
        $token = $this->tokens->register($request->user(), $request->validated());

        return response()->json([
            'data' => [
                'id' => $token->id,
                'platform' => $token->platform?->value,
                'device_name' => $token->device_name,
                'last_used_at' => $token->last_used_at?->toIso8601String(),
            ],
            'message' => 'Device token registered.',
            'push_configured' => app(PushNotificationSender::class)->isConfigured(),
        ], 201);
    }

    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        $this->tokens->invalidate($request->user(), $validated['token']);

        return response()->json([
            'message' => 'Device token invalidated.',
        ]);
    }
}
