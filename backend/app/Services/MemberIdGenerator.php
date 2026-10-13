<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class MemberIdGenerator
{
    /**
     * Generate a unique member ID using a year-based sequential format.
     * Example: BYN-2026-0001
     *
     * Business modules may later customize the prefix or sequence rules.
     */
    public function generate(?int $year = null): string
    {
        $year ??= (int) now()->format('Y');
        $prefix = sprintf('BYN-%d-', $year);

        return DB::transaction(function () use ($prefix) {
            $latest = User::query()
                ->where('member_id', 'like', $prefix.'%')
                ->lockForUpdate()
                ->orderByDesc('member_id')
                ->value('member_id');

            $sequence = 1;

            if (is_string($latest) && preg_match('/(\d+)$/', $latest, $matches) === 1) {
                $sequence = ((int) $matches[1]) + 1;
            }

            return $prefix.str_pad((string) $sequence, 4, '0', STR_PAD_LEFT);
        });
    }
}
