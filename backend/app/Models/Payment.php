<?php

namespace App\Models;

use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Payment extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'user_id',
        'amount',
        'currency',
        'method',
        'received_at',
        'recorded_by',
        'status',
        'receipt_number',
        'idempotency_key',
        'notes',
        'reversed_at',
        'reversed_by',
        'reversal_reason',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'string',
            'method' => PaymentMethod::class,
            'status' => PaymentStatus::class,
            'received_at' => 'datetime',
            'reversed_at' => 'datetime',
        ];
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    public function reversedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reversed_by');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }

    public function isPosted(): bool
    {
        return $this->status === PaymentStatus::Posted;
    }
}
