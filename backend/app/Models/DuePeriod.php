<?php

namespace App\Models;

use App\Models\Concerns\PreventsDestructiveFinancialDeletes;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DuePeriod extends Model
{
    use PreventsDestructiveFinancialDeletes;

    protected $fillable = [
        'year',
        'month',
        'label',
        'starts_on',
        'ends_on',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'starts_on' => 'date',
            'ends_on' => 'date',
        ];
    }

    public function dues(): HasMany
    {
        return $this->hasMany(MemberDue::class);
    }
}
