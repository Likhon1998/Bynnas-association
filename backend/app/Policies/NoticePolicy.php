<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Notice;
use App\Models\User;

class NoticePolicy
{
    public function viewAny(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
            UserRole::Member,
        );
    }

    public function view(User $actor, Notice $notice): bool
    {
        if ($actor->hasRole(UserRole::SuperAdmin, UserRole::Admin, UserRole::Accountant)) {
            return true;
        }

        if (! $actor->isMember()) {
            return false;
        }

        return Notice::query()
            ->visibleToMember($actor)
            ->whereKey($notice->id)
            ->exists();
    }

    public function create(User $actor): bool
    {
        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function update(User $actor, Notice $notice): bool
    {
        return $this->create($actor);
    }

    public function publish(User $actor, Notice $notice): bool
    {
        return $this->create($actor);
    }

    public function archive(User $actor, Notice $notice): bool
    {
        return $this->create($actor);
    }
}
