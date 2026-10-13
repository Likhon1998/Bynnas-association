<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\User;

class MemberPolicy
{
    public function viewAny(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function view(User $actor, User $member): bool
    {
        if (! $member->isMember()) {
            return false;
        }

        if ($actor->id === $member->id) {
            return true;
        }

        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function create(User $actor): bool
    {
        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function update(User $actor, User $member): bool
    {
        if (! $member->isMember()) {
            return false;
        }

        if ($actor->id === $member->id) {
            return true;
        }

        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function deactivate(User $actor, User $member): bool
    {
        if (! $member->isMember()) {
            return false;
        }

        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function reactivate(User $actor, User $member): bool
    {
        return $this->deactivate($actor, $member);
    }

    public function delete(User $actor, User $member): bool
    {
        // Financial history must never be removed via hard delete.
        return false;
    }
}
