<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ReversePaymentRequest;
use App\Http\Requests\Api\V1\StorePaymentRequest;
use App\Http\Resources\Api\V1\PaymentResource;
use App\Models\Payment;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Throwable;

class PaymentController extends Controller
{
    public function __construct(
        private readonly PaymentService $payments,
        private readonly FinancePolicy $policy,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        /** @var User $actor */
        $actor = $request->user();

        if ($actor->isMember()) {
            return PaymentResource::collection(
                $this->payments->paginateForMember(
                    $actor,
                    min(max((int) $request->integer('per_page', 15), 1), 100),
                )
            );
        }

        abort_unless($this->policy->viewAnyFinancial($actor), 403);

        return PaymentResource::collection(
            $this->payments->paginateAll(
                userId: $request->filled('user_id') ? (int) $request->integer('user_id') : null,
                status: $request->string('status')->toString() ?: null,
                perPage: min(max((int) $request->integer('per_page', 15), 1), 100),
            )
        );
    }

    public function store(StorePaymentRequest $request): JsonResponse
    {
        try {
            $payment = $this->payments->post($request->user(), $request->validated());
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $created = $payment->wasRecentlyCreated;
        $status = $created ? 201 : 200;

        return response()->json([
            'data' => new PaymentResource($payment),
            'message' => $created
                ? 'Payment recorded.'
                : 'Existing payment returned for idempotency key.',
            'idempotent_replay' => ! $created,
        ], $status);
    }

    public function show(Request $request, Payment $payment): PaymentResource
    {
        /** @var User $actor */
        $actor = $request->user();
        $payment->loadMissing(['allocations.memberDue.period', 'member', 'recordedBy']);

        abort_unless($this->policy->viewMemberFinancial($actor, $payment->member), 403);

        return new PaymentResource($payment);
    }

    public function reverse(ReversePaymentRequest $request, Payment $payment): PaymentResource|JsonResponse
    {
        try {
            $reversed = $this->payments->reverse($request->user(), $payment, $request->validated('reason'));
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return new PaymentResource($reversed);
    }
}
