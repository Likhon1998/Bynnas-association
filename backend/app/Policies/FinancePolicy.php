<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Payment;
use App\Models\User;

class FinancePolicy
{
    public function managePlans(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function manageAssignments(User $actor): bool
    {
        return $this->managePlans($actor);
    }

    public function generateDues(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function viewAnyFinancial(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function viewMemberFinancial(User $actor, User $member): bool
    {
        if (! $member->isMember()) {
            return false;
        }

        if ($actor->id === $member->id) {
            return true;
        }

        return $this->viewAnyFinancial($actor);
    }

    public function recordPayment(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function reversePayment(User $actor, Payment $payment): bool
    {
        return $this->recordPayment($actor);
    }

    public function voidDue(User $actor): bool
    {
        return $actor->hasRole(UserRole::SuperAdmin, UserRole::Admin);
    }

    public function viewDashboard(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
            UserRole::Member,
        );
    }

    public function viewReports(User $actor): bool
    {
        return $actor->hasRole(
            UserRole::SuperAdmin,
            UserRole::Admin,
            UserRole::Accountant,
        );
    }

    public function exportReports(User $actor): bool
    {
        return $this->viewReports($actor);
    }
}
