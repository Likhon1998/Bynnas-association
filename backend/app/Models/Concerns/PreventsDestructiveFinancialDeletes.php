<?php

namespace App\Models\Concerns;

use LogicException;

trait PreventsDestructiveFinancialDeletes
{
    public static function bootPreventsDestructiveFinancialDeletes(): void
    {
        static::deleting(function () {
            throw new LogicException('Financial records cannot be deleted. Use void or reversal.');
        });
    }
}
