<?php

namespace App\Http\Requests\Api\V1;

use App\Policies\FinancePolicy;
use Illuminate\Foundation\Http\FormRequest;

class UpdateContributionPlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && app(FinancePolicy::class)->managePlans($user);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'default_amount' => ['sometimes', 'regex:/^\d+(\.\d{1,2})?$/'],
            'currency' => ['sometimes', 'string', 'size:3'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
