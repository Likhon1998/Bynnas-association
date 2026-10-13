<?php

namespace App\Enums;

enum NoticeAudienceType: string
{
    case AllActiveMembers = 'all_active_members';
    case SelectedMembers = 'selected_members';
    case Role = 'role';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
