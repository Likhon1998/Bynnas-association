<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use RuntimeException;

class StaffUserService
{
    /**
     * @param  array{
     *     name: string,
     *     email: string,
     *     role: string,
     *     password?: string|null,
     * }  $data
     * @return array{user: User, temporary_password: string|null}
     */
    public function createStaff(User $actor, array $data): array
    {
        if (! $actor->hasRole(UserRole::SuperAdmin)) {
            throw new RuntimeException('Only Super Admin can create staff accounts.');
        }

        $role = UserRole::from($data['role']);
        if (! $role->isStaff() || $role === UserRole::SuperAdmin) {
            throw new RuntimeException('Role must be admin or accountant.');
        }

        return DB::transaction(function () use ($data, $role) {
            $temporaryPassword = $data['password'] ?? Str::password(12);

            $user = User::query()->create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make($temporaryPassword),
                'role' => $role,
                'member_id' => null,
                'is_active' => true,
                'email_verified_at' => now(),
            ]);

            return [
                'user' => $user,
                'temporary_password' => array_key_exists('password', $data) && filled($data['password'])
                    ? null
                    : $temporaryPassword,
            ];
        });
    }
}
