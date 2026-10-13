<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\PaymentMethod;
use App\Policies\FinancePolicy;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null && app(FinancePolicy::class)->recordPayment($user);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'amount' => ['required', 'regex:/^\d+(\.\d{1,2})?$/'],
            'method' => ['required', Rule::in(PaymentMethod::values())],
            'received_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'currency' => ['nullable', 'string', 'size:3'],
            'idempotency_key' => ['required', 'string', 'max:100'],
            'allocations' => ['nullable', 'array'],
            'allocations.*.member_due_id' => ['required_with:allocations', 'integer', 'exists:member_dues,id'],
            'allocations.*.amount' => ['required_with:allocations', 'regex:/^\d+(\.\d{1,2})?$/'],
        ];
    }
}
