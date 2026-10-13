<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\User;

class UserPolicy
{
    public function viewAny(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function view(User $actor, User $target): bool
    {
        if ($actor->id === $target->id) {
            return true;
        }

        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function update(User $actor, User $target): bool
    {
        if ($actor->id === $target->id) {
            return true;
        }

        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function manageRoles(User $actor): bool
    {
        return $actor->hasRole(UserRole::SuperAdmin);
    }
}
