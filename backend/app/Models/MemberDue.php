<?php

namespace App\Models;

use App\Enums\MemberDueStatus;
use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use App\Support\Money;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MemberDue extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'user_id',
        'due_period_id',
        'contribution_plan_id',
        'amount_due',
        'amount_allocated',
        'status',
        'currency',
        'idempotency_key',
        'voided_at',
        'voided_by',
        'void_reason',
    ];

    protected function casts(): array
    {
        return [
            'amount_due' => 'string',
            'amount_allocated' => 'string',
            'status' => MemberDueStatus::class,
            'voided_at' => 'datetime',
        ];
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(DuePeriod::class, 'due_period_id');
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(ContributionPlan::class, 'contribution_plan_id');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }

    public function voidedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'voided_by');
    }

    public function outstandingBalance(): string
    {
        if ($this->status === MemberDueStatus::Voided) {
            return Money::normalize('0');
        }

        return Money::sub((string) $this->amount_due, (string) $this->amount_allocated);
    }

    public function refreshStatusFromAllocation(): void
    {
        if ($this->status === MemberDueStatus::Voided) {
            return;
        }

        $allocated = Money::normalize((string) $this->amount_allocated);
        $due = Money::normalize((string) $this->amount_due);

        if (Money::isZero($allocated)) {
            $this->status = MemberDueStatus::Pending;
        } elseif (Money::compare($allocated, $due) >= 0) {
            $this->status = MemberDueStatus::Paid;
        } else {
            $this->status = MemberDueStatus::Partial;
        }
    }
}
