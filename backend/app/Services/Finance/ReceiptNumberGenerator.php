<?php

namespace App\Services\Finance;

use App\Models\Payment;
use Illuminate\Support\Facades\DB;

class ReceiptNumberGenerator
{
    public function generate(): string
    {
        $date = now()->format('Ymd');
        $prefix = 'RCPT-'.$date.'-';

        return DB::transaction(function () use ($prefix) {
            $latest = Payment::query()
                ->where('receipt_number', 'like', $prefix.'%')
                ->lockForUpdate()
                ->orderByDesc('receipt_number')
                ->value('receipt_number');

            $sequence = 1;
            if (is_string($latest) && preg_match('/-(\d{6})$/', $latest, $matches) === 1) {
                $sequence = ((int) $matches[1]) + 1;
            }

            return $prefix.str_pad((string) $sequence, 6, '0', STR_PAD_LEFT);
        });
    }
}
