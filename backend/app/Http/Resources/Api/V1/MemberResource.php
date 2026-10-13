<?php

namespace App\Http\Resources\Api\V1;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin User */
class MemberResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $isStaff = $request->user()?->isStaff() ?? false;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role?->value,
            'member_id' => $this->member_id,
            'is_active' => $this->is_active,
            'deactivated_at' => $this->deactivated_at?->toIso8601String(),
            'phone' => $this->memberProfile?->phone,
            'address' => $this->memberProfile?->address,
            'notes' => $this->when($isStaff, $this->memberProfile?->notes),
            'joined_on' => $this->memberProfile?->joined_on?->toDateString(),
            'email_verified_at' => $this->email_verified_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
