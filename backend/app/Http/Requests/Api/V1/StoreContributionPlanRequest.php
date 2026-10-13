<?php

namespace App\Http\Requests\Api\V1;

use App\Policies\FinancePolicy;
use Illuminate\Foundation\Http\FormRequest;

class StoreContributionPlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && app(FinancePolicy::class)->managePlans($user);
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('code')) {
            $this->merge([
                'code' => strtoupper((string) $this->input('code')),
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:64', 'alpha_dash', 'unique:contribution_plans,code'],
            'description' => ['nullable', 'string', 'max:2000'],
            'default_amount' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'currency' => ['nullable', 'string', 'size:3'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
