<?php

namespace App\Enums;

enum UserRole: string
{
    case SuperAdmin = 'super_admin';
    case Admin = 'admin';
    case Accountant = 'accountant';
    case Member = 'member';

    public function label(): string
    {
        return match ($this) {
            self::SuperAdmin => 'Super Admin',
            self::Admin => 'Admin',
            self::Accountant => 'Accountant',
            self::Member => 'Member',
        };
    }

    public function isStaff(): bool
    {
        return match ($this) {
            self::SuperAdmin, self::Admin, self::Accountant => true,
            self::Member => false,
        };
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
