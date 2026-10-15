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
        $this->renameDemoEmail('member@bynnas.test', 'member@bynnasassociation.com');
        $this->renameDemoEmail('admin@bynnas.test', 'admin@bynnasassociation.com');
        $this->renameDemoEmail('accountant@bynnas.test', 'accountant@bynnasassociation.com');
        $this->renameDemoEmail('superadmin@bynnas.test', 'superadmin@bynnasassociation.com');

        $member = User::query()->updateOrCreate(
            ['email' => 'member@bynnasassociation.com'],
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
            ['email' => 'admin@bynnasassociation.com'],
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
            ['email' => 'accountant@bynnasassociation.com'],
            [
                'name' => 'Demo Accountant',
                'password' => Hash::make('password'),
                'role' => UserRole::Accountant,
                'member_id' => null,
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        User::query()->updateOrCreate(
            ['email' => 'superadmin@bynnasassociation.com'],
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

    private function renameDemoEmail(string $from, string $to): void
    {
        $existing = User::query()->where('email', $from)->first();
        if ($existing === null) {
            return;
        }

        if (User::query()->where('email', $to)->exists()) {
            $existing->delete();

            return;
        }

        $existing->forceFill(['email' => $to])->save();
    }
}
