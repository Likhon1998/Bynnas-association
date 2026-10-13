<?php

namespace App\Models;

use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentAllocation extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'payment_id',
        'member_due_id',
        'amount',
        'is_reversed',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'string',
            'is_reversed' => 'boolean',
        ];
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function memberDue(): BelongsTo
    {
        return $this->belongsTo(MemberDue::class);
    }
}
