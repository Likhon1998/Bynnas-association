<?php

namespace App\Models;

use App\Enums\NoticeAudienceType;
use App\Enums\NoticeStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Notice extends Model
{
    protected $fillable = [
        'title',
        'body',
        'status',
        'audience_type',
        'audience_role',
        'publish_at',
        'expires_at',
        'published_at',
        'archived_at',
        'created_by',
        'updated_by',
        'recipient_count',
    ];

    protected function casts(): array
    {
        return [
            'status' => NoticeStatus::class,
            'audience_type' => NoticeAudienceType::class,
            'publish_at' => 'datetime',
            'expires_at' => 'datetime',
            'published_at' => 'datetime',
            'archived_at' => 'datetime',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function targets(): HasMany
    {
        return $this->hasMany(NoticeTarget::class);
    }

    public function targetMembers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'notice_targets')->withTimestamps();
    }

    public function isVisibleNow(): bool
    {
        if ($this->status !== NoticeStatus::Published) {
            return false;
        }

        if ($this->publish_at !== null && $this->publish_at->isFuture()) {
            return false;
        }

        if ($this->expires_at !== null && $this->expires_at->isPast()) {
            return false;
        }

        return true;
    }

    public function scopeVisibleToMember(Builder $query, User $member): Builder
    {
        return $query
            ->where('status', NoticeStatus::Published)
            ->where(function (Builder $builder) {
                $builder->whereNull('publish_at')->orWhere('publish_at', '<=', now());
            })
            ->where(function (Builder $builder) {
                $builder->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->where(function (Builder $builder) use ($member) {
                $builder->where('audience_type', NoticeAudienceType::AllActiveMembers)
                    ->orWhere(function (Builder $roleQuery) use ($member) {
                        $roleQuery->where('audience_type', NoticeAudienceType::Role)
                            ->where('audience_role', $member->role?->value);
                    })
                    ->orWhere(function (Builder $selected) use ($member) {
                        $selected->where('audience_type', NoticeAudienceType::SelectedMembers)
                            ->whereHas('targets', fn (Builder $t) => $t->where('user_id', $member->id));
                    });
            });
    }
}
