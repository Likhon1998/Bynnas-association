<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with local development accounts.
     */
    public function run(): void
    {
        $member = User::query()->updateOrCreate(
            ['email' => 'member@bynnas.test'],
            [
                'name' => 'Demo Member',
                'password' => Hash::make('password'),
                'role' => UserRole::Member,
                'member_id' => 'BYN-2026-0001',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $member->memberProfile()->updateOrCreate(
            ['user_id' => $member->id],
            [
                'phone' => '+8801700000001',
                'address' => 'Dhaka, Bangladesh',
                'notes' => 'Seeded demo member',
                'joined_on' => now()->toDateString(),
            ]
        );

        User::query()->updateOrCreate(
            ['email' => 'admin@bynnas.test'],
            [
                'name' => 'Demo Admin',
                'password' => Hash::make('password'),
                'role' => UserRole::Admin,
                'member_id' => null,
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        User::query()->updateOrCreate(
            ['email' => 'superadmin@bynnas.test'],
            [
                'name' => 'Demo Super Admin',
                'password' => Hash::make('password'),
                'role' => UserRole::SuperAdmin,
                'member_id' => null,
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );
    }
}
