<?php

namespace App\Services\Finance;

use App\Enums\MemberDueStatus;
use App\Models\MemberDue;
use App\Models\User;
use App\Support\Money;

class BalanceService
{
    /**
     * @return array{
     *     user_id: int,
     *     currency: string,
     *     total_due: string,
     *     total_allocated: string,
     *     outstanding: string,
     *     dues_count: int,
     * }
     */
    public function outstandingForMember(User $member): array
    {
        $dues = MemberDue::query()
            ->where('user_id', $member->id)
            ->where('status', '!=', MemberDueStatus::Voided)
            ->get();

        $totalDue = Money::normalize('0');
        $totalAllocated = Money::normalize('0');

        foreach ($dues as $due) {
            $totalDue = Money::add($totalDue, (string) $due->amount_due);
            $totalAllocated = Money::add($totalAllocated, (string) $due->amount_allocated);
        }

        return [
            'user_id' => $member->id,
            'currency' => 'BDT',
            'total_due' => $totalDue,
            'total_allocated' => $totalAllocated,
            'outstanding' => Money::sub($totalDue, $totalAllocated),
            'dues_count' => $dues->count(),
        ];
    }
}
