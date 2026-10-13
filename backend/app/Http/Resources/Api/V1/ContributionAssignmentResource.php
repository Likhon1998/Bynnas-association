<?php

namespace App\Http\Resources\Api\V1;

use App\Models\MemberContributionAssignment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin MemberContributionAssignment */
class ContributionAssignmentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'contribution_plan_id' => $this->contribution_plan_id,
            'amount' => $this->amount !== null ? (string) $this->amount : null,
            'effective_from' => $this->effective_from?->toDateString(),
            'effective_to' => $this->effective_to?->toDateString(),
            'is_active' => $this->is_active,
            'plan' => new ContributionPlanResource($this->whenLoaded('plan')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
