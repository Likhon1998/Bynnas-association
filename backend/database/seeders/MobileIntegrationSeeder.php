<?php

namespace Database\Seeders;

use App\Enums\AppNotificationType;
use App\Enums\NoticeAudienceType;
use App\Enums\NoticeStatus;
use App\Enums\UserRole;
use App\Models\ContributionPlan;
use App\Models\Notice;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use App\Services\Notices\NoticeService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Deterministic fixture data for Flutter ↔ Laravel integration tests.
 * Credentials come from env (see .env.integration.example); never commit secrets.
 */
class MobileIntegrationSeeder extends Seeder
{
    public function run(): void
    {
        $memberPassword = env('INTEGRATION_MEMBER_PASSWORD', 'password');
        $otherPassword = env('INTEGRATION_OTHER_MEMBER_PASSWORD', 'password');
        $adminPassword = env('INTEGRATION_ADMIN_PASSWORD', 'password');

        $memberEmail = env('INTEGRATION_MEMBER_EMAIL', 'integration.member@bynnas.test');
        $otherEmail = env('INTEGRATION_OTHER_MEMBER_EMAIL', 'integration.other@bynnas.test');
        $adminEmail = env('INTEGRATION_ADMIN_EMAIL', 'integration.admin@bynnas.test');

        $member = User::query()->updateOrCreate(
            ['email' => $memberEmail],
            [
                'name' => 'Integration Member',
                'password' => Hash::make($memberPassword),
                'role' => UserRole::Member,
                'member_id' => 'BYN-INT-0001',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );
        $member->memberProfile()->updateOrCreate(
            ['user_id' => $member->id],
            [
                'phone' => '+8801711000001',
                'address' => 'Integration City',
                'joined_on' => '2026-01-01',
            ]
        );

        $other = User::query()->updateOrCreate(
            ['email' => $otherEmail],
            [
                'name' => 'Integration Other',
                'password' => Hash::make($otherPassword),
                'role' => UserRole::Member,
                'member_id' => 'BYN-INT-0002',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );
        $other->memberProfile()->updateOrCreate(
            ['user_id' => $other->id],
            [
                'phone' => '+8801711000002',
                'address' => 'Other City',
                'joined_on' => '2026-01-02',
            ]
        );

        $admin = User::query()->updateOrCreate(
            ['email' => $adminEmail],
            [
                'name' => 'Integration Admin',
                'password' => Hash::make($adminPassword),
                'role' => UserRole::Admin,
                'member_id' => null,
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $plan = ContributionPlan::query()->updateOrCreate(
            ['code' => 'INT-MONTHLY'],
            [
                'name' => 'Integration Monthly',
                'description' => 'Fixture plan',
                'default_amount' => '500.00',
                'currency' => 'BDT',
                'is_active' => true,
            ]
        );

        $dues = app(DueService::class)->generateForPeriod(
            $admin,
            2026,
            3,
            $plan->id,
            $member->id,
        );
        $due = $dues['dues'][0];

        app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '200.00',
            'method' => 'cash',
            'received_at' => '2026-03-10 10:00:00',
            'idempotency_key' => 'integration-seed-pay-1',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '200.00'],
            ],
        ]);

        $notice = Notice::query()->where('title', 'Integration Notice')->first();
        if ($notice === null) {
            $notice = app(NoticeService::class)->create($admin, [
                'title' => 'Integration Notice',
                'body' => 'Hello from the integration fixture.',
                'audience_type' => NoticeAudienceType::AllActiveMembers->value,
                'publish_at' => now()->subHour()->toDateTimeString(),
            ]);
            app(NoticeService::class)->publish($admin, $notice);
        } else {
            $notice->forceFill([
                'status' => NoticeStatus::Published,
                'body' => 'Hello from the integration fixture.',
                'publish_at' => now()->subHour(),
                'published_at' => now()->subHour(),
            ])->save();
        }

        UserNotification::query()->updateOrCreate(
            [
                'user_id' => $member->id,
                'dedupe_key' => 'integration:seed:notice',
            ],
            [
                'type' => AppNotificationType::Notice,
                'title' => 'Integration Notice',
                'body' => 'Hello from the integration fixture.',
                'data' => ['notice_id' => $notice->id],
                'read_at' => null,
            ]
        );

        UserNotification::query()->updateOrCreate(
            [
                'user_id' => $member->id,
                'dedupe_key' => 'integration:seed:read',
            ],
            [
                'type' => AppNotificationType::DuesReminder,
                'title' => 'Already read reminder',
                'body' => 'This notification is already read.',
                'data' => null,
                'read_at' => now(),
            ]
        );
    }
}
