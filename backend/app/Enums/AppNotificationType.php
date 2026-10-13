<?php

namespace App\Enums;

enum AppNotificationType: string
{
    case Notice = 'notice';
    case PaymentRecorded = 'payment_recorded';
    case DuesReminder = 'dues_reminder';
    case OutstandingDues = 'outstanding_dues';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
