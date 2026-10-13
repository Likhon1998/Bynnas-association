<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Notice;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Notice */
class NoticeResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $isStaff = $request->user()?->isStaff() ?? false;

        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'status' => $this->status?->value,
            'audience_type' => $this->audience_type?->value,
            'audience_role' => $this->audience_role,
            'publish_at' => $this->publish_at?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'published_at' => $this->published_at?->toIso8601String(),
            'archived_at' => $this->archived_at?->toIso8601String(),
            'recipient_count' => $this->when($isStaff, $this->recipient_count),
            'member_ids' => $this->when(
                $isStaff && $this->relationLoaded('targets'),
                fn () => $this->targets->pluck('user_id')->values(),
            ),
            'created_by' => $this->when($isStaff, $this->created_by),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
