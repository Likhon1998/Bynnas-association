<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\NoticeAudienceType;
use App\Enums\UserRole;
use App\Policies\NoticePolicy;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreNoticeRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && app(NoticePolicy::class)->create($user);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string', 'max:10000'],
            'audience_type' => ['required', Rule::in(NoticeAudienceType::values())],
            'audience_role' => ['nullable', Rule::requiredIf(fn () => $this->input('audience_type') === NoticeAudienceType::Role->value), Rule::in(UserRole::values())],
            'member_ids' => ['nullable', 'array', Rule::requiredIf(fn () => $this->input('audience_type') === NoticeAudienceType::SelectedMembers->value)],
            'member_ids.*' => ['integer', 'exists:users,id'],
            'publish_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:publish_at'],
        ];
    }
}
