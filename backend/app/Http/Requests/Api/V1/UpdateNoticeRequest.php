<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\NoticeAudienceType;
use App\Enums\UserRole;
use App\Policies\NoticePolicy;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateNoticeRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        $notice = $this->route('notice');

        return $user !== null
            && $notice !== null
            && app(NoticePolicy::class)->update($user, $notice);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'string', 'max:255'],
            'body' => ['sometimes', 'string', 'max:10000'],
            'audience_type' => ['sometimes', Rule::in(NoticeAudienceType::values())],
            'audience_role' => ['nullable', Rule::in(UserRole::values())],
            'member_ids' => ['nullable', 'array'],
            'member_ids.*' => ['integer', 'exists:users,id'],
            'publish_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:publish_at'],
        ];
    }
}
