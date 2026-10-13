<?php

namespace App\Enums;

enum MemberDueStatus: string
{
    case Pending = 'pending';
    case Partial = 'partial';
    case Paid = 'paid';
    case Voided = 'voided';
}
