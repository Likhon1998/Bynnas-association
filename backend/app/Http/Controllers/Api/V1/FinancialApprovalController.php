<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\FinancialChangeRequest;
use App\Models\Payment;
use App\Services\Finance\FinancialApprovalService;
use App\Services\Finance\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class FinancialApprovalController extends Controller
{
    public function __construct(
        private readonly FinancialApprovalService $approvals,
        private readonly PaymentService $payments,
    ) {}

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()?->isStaff(), 403);

        $items = FinancialChangeRequest::query()
            ->with(['payment', 'requester', 'reviewer'])
            ->when(
                $request->string('status')->toString() ?: null,
                fn ($q, $status) => $q->where('status', $status),
            )
            ->latest('id')
            ->limit(50)
            ->get();

        return response()->json(['data' => $items]);
    }

    public function requestReverse(Request $request, Payment $payment): JsonResponse
    {
        abort_unless($request->user()?->isStaff(), 403);

        $data = $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);

        $actor = $request->user();

        // Super Admin / Admin may reverse immediately; others queue for approval.
        if ($actor->hasRole(UserRole::SuperAdmin, UserRole::Admin)) {
            try {
                $reversed = $this->payments->reverse($actor, $payment, $data['reason']);
            } catch (Throwable $e) {
                return response()->json(['message' => $e->getMessage()], 422);
            }

            return response()->json([
                'data' => $reversed,
                'message' => 'Payment reversed.',
                'immediate' => true,
            ]);
        }

        try {
            $change = $this->approvals->requestPaymentReverse($actor, $payment, $data['reason']);
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => $change,
            'message' => 'Reversal submitted for admin approval.',
            'immediate' => false,
        ], 201);
    }

    public function approve(Request $request, FinancialChangeRequest $financialChangeRequest): JsonResponse
    {
        $data = $request->validate([
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        try {
            $item = $this->approvals->approve(
                $request->user(),
                $financialChangeRequest,
                $data['note'] ?? null,
            );
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => $item,
            'message' => 'Request approved.',
        ]);
    }

    public function reject(Request $request, FinancialChangeRequest $financialChangeRequest): JsonResponse
    {
        $data = $request->validate([
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        try {
            $item = $this->approvals->reject(
                $request->user(),
                $financialChangeRequest,
                $data['note'] ?? null,
            );
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => $item,
            'message' => 'Request rejected.',
        ]);
    }
}
