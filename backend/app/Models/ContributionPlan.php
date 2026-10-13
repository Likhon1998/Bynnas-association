<?php

namespace App\Models;

use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ContributionPlan extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'name',
        'code',
        'description',
        'default_amount',
        'currency',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'default_amount' => 'string',
            'is_active' => 'boolean',
        ];
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(MemberContributionAssignment::class);
    }

    public function dues(): HasMany
    {
        return $this->hasMany(MemberDue::class);
    }
}
