<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Payment;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Payment */
class PaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'amount' => Money::normalize((string) $this->amount),
            'currency' => $this->currency,
            'method' => $this->method?->value,
            'received_at' => $this->received_at?->toIso8601String(),
            'recorded_by' => $this->recorded_by,
            'status' => $this->status?->value,
            'receipt_number' => $this->receipt_number,
            'idempotency_key' => $this->idempotency_key,
            'notes' => $this->notes,
            'reversed_at' => $this->reversed_at?->toIso8601String(),
            'reversal_reason' => $this->reversal_reason,
            'allocations' => PaymentAllocationResource::collection($this->whenLoaded('allocations')),
            'member' => $this->whenLoaded('member', fn () => [
                'id' => $this->member->id,
                'name' => $this->member->name,
                'member_id' => $this->member->member_id,
                'email' => $this->member->email,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
