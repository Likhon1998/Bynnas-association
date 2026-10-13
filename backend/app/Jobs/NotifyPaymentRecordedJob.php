<?php

namespace App\Jobs;

use App\Enums\AppNotificationType;
use App\Enums\PaymentStatus;
use App\Models\Payment;
use App\Services\Notifications\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class NotifyPaymentRecordedJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(
        public readonly int $paymentId,
    ) {}

    public function handle(NotificationService $notifications): void
    {
        $payment = Payment::query()->with('member')->find($this->paymentId);
        if ($payment === null || $payment->status !== PaymentStatus::Posted || $payment->member === null) {
            return;
        }

        $notifications->notify(
            user: $payment->member,
            type: AppNotificationType::PaymentRecorded,
            title: 'Payment recorded',
            body: sprintf(
                'A payment of %s %s was recorded (receipt %s).',
                $payment->amount,
                $payment->currency,
                $payment->receipt_number,
            ),
            dedupeKey: sprintf('payment:%d:recorded', $payment->id),
            data: [
                'payment_id' => $payment->id,
                'receipt_number' => $payment->receipt_number,
                'amount' => (string) $payment->amount,
            ],
        );
    }

    public function failed(\Throwable $e): void
    {
        Log::error('NotifyPaymentRecordedJob failed', [
            'payment_id' => $this->paymentId,
            'error' => $e->getMessage(),
        ]);
    }
}
