<?php

namespace App\Models;

use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MemberContributionAssignment extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'user_id',
        'contribution_plan_id',
        'amount',
        'effective_from',
        'effective_to',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'string',
            'effective_from' => 'date',
            'effective_to' => 'date',
            'is_active' => 'boolean',
        ];
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(ContributionPlan::class, 'contribution_plan_id');
    }
}
