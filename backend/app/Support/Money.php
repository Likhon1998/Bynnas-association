<?php

namespace App\Support;

use InvalidArgumentException;

/**
 * Fixed-precision money helper using BCMath decimal strings.
 */
final class Money
{
    public const SCALE = 2;

    public static function normalize(string|int|float $value): string
    {
        if (is_float($value)) {
            throw new InvalidArgumentException('Floating-point money values are not allowed.');
        }

        $string = is_int($value) ? (string) $value : trim((string) $value);

        if ($string === '' || ! preg_match('/^-?\d+(\.\d+)?$/', $string)) {
            throw new InvalidArgumentException('Invalid money amount.');
        }

        return bcadd($string, '0', self::SCALE);
    }

    public static function add(string $left, string $right): string
    {
        return bcadd(self::normalize($left), self::normalize($right), self::SCALE);
    }

    public static function sub(string $left, string $right): string
    {
        return bcsub(self::normalize($left), self::normalize($right), self::SCALE);
    }

    public static function compare(string $left, string $right): int
    {
        return bccomp(self::normalize($left), self::normalize($right), self::SCALE);
    }

    public static function isZero(string $value): bool
    {
        return self::compare($value, '0') === 0;
    }

    public static function isPositive(string $value): bool
    {
        return self::compare($value, '0') === 1;
    }

    public static function min(string $left, string $right): string
    {
        return self::compare($left, $right) <= 0 ? self::normalize($left) : self::normalize($right);
    }
}
