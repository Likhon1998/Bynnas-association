<?php

namespace App\Http\Requests\Api\V1;

use App\Policies\FinancePolicy;
use Illuminate\Foundation\Http\FormRequest;

class StoreContributionAssignmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && app(FinancePolicy::class)->manageAssignments($user);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'contribution_plan_id' => ['required', 'integer', 'exists:contribution_plans,id'],
            'amount' => ['nullable', 'regex:/^\d+(\.\d{1,2})?$/'],
            'effective_from' => ['required', 'date'],
            'effective_to' => ['nullable', 'date', 'after_or_equal:effective_from'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
