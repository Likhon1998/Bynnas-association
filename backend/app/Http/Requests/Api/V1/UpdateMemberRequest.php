<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\UserRole;
use App\Models\User;
use App\Policies\MemberPolicy;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UpdateMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var User $member */
        $member = $this->route('member');
        $user = $this->user();

        return $user !== null && app(MemberPolicy::class)->update($user, $member);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        /** @var User $member */
        $member = $this->route('member');
        $isSelf = $this->user()?->id === $member->id;
        $isStaffEditor = $this->user()?->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
        ) ?? false;

        $rules = [
            'phone' => ['nullable', 'string', 'max:32'],
            'address' => ['nullable', 'string', 'max:500'],
            'occupation' => ['nullable', 'string', 'max:120'],
        ];

        if ($isStaffEditor) {
            $rules = array_merge($rules, [
                'name' => ['sometimes', 'required', 'string', 'max:255'],
                'email' => [
                    'sometimes',
                    'required',
                    'string',
                    'email',
                    'max:255',
                    Rule::unique('users', 'email')->ignore($member->id),
                ],
                'notes' => ['nullable', 'string', 'max:2000'],
                'joined_on' => ['nullable', 'date'],
                'password' => ['nullable', 'confirmed', Password::defaults()],
            ]);
        } elseif ($isSelf) {
            $rules = array_merge($rules, [
                'name' => ['sometimes', 'required', 'string', 'max:255'],
            ]);
        }

        return $rules;
    }
}
