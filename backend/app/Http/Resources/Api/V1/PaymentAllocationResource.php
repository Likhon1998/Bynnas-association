<?php

namespace App\Http\Resources\Api\V1;

use App\Models\PaymentAllocation;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin PaymentAllocation */
class PaymentAllocationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'payment_id' => $this->payment_id,
            'member_due_id' => $this->member_due_id,
            'amount' => Money::normalize((string) $this->amount),
            'is_reversed' => $this->is_reversed,
            'member_due' => new MemberDueResource($this->whenLoaded('memberDue')),
        ];
    }
}
