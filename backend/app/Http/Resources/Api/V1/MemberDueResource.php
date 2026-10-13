<?php

namespace App\Http\Resources\Api\V1;

use App\Models\MemberDue;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin MemberDue */
class MemberDueResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'due_period_id' => $this->due_period_id,
            'contribution_plan_id' => $this->contribution_plan_id,
            'amount_due' => Money::normalize((string) $this->amount_due),
            'amount_allocated' => Money::normalize((string) $this->amount_allocated),
            'outstanding' => $this->outstandingBalance(),
            'status' => $this->status?->value,
            'currency' => $this->currency,
            'period' => $this->whenLoaded('period', fn () => [
                'id' => $this->period->id,
                'label' => $this->period->label,
                'year' => $this->period->year,
                'month' => $this->period->month,
            ]),
            'plan' => new ContributionPlanResource($this->whenLoaded('plan')),
            'voided_at' => $this->voided_at?->toIso8601String(),
            'void_reason' => $this->void_reason,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
