<?php

namespace App\Http\Requests\Api\V1;

use App\Policies\FinancePolicy;
use Illuminate\Foundation\Http\FormRequest;

class ReversePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        $payment = $this->route('payment');

        return $user !== null
            && $payment !== null
            && app(FinancePolicy::class)->reversePayment($user, $payment);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'max:500'],
        ];
    }
}
