<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\SmsMessage;
use App\Services\Sms\SmsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SmsController extends Controller
{
    public function __construct(
        private readonly SmsService $sms,
    ) {}

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
        ), 403);

        $items = SmsMessage::query()
            ->withCount([
                'deliveries as sent_count' => fn ($q) => $q->where('status', 'sent'),
                'deliveries as failed_count' => fn ($q) => $q->where('status', 'failed'),
            ])
            ->latest('id')
            ->limit(50)
            ->get();

        return response()->json(['data' => $items]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
        ), 403);

        $data = $request->validate([
            'body' => ['required', 'string', 'max:1000'],
            'audience_type' => ['nullable', 'in:all_active_members,selected_members'],
            'member_ids' => ['nullable', 'array'],
            'member_ids.*' => ['integer', 'exists:users,id'],
        ]);

        $message = $this->sms->sendBroadcast($request->user(), $data);

        return response()->json([
            'data' => $message,
            'message' => 'SMS broadcast processed.',
        ], 201);
    }

    public function show(Request $request, SmsMessage $smsMessage): JsonResponse
    {
        abort_unless($request->user()?->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
        ), 403);

        $smsMessage->load(['deliveries.user', 'creator']);

        return response()->json(['data' => $smsMessage]);
    }
}
