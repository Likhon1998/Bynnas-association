<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AppNotificationType;
use App\Jobs\DeliverNoticeChunkJob;
use App\Jobs\NotifyPaymentRecordedJob;
use App\Jobs\PublishNoticeJob;
use App\Models\DeviceToken;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use App\Services\Notices\NoticeService;
use App\Services\Notifications\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NoticeNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_cannot_create_or_publish_notices(): void
    {
        $member = User::factory()->member()->create();
        Sanctum::actingAs($member);

        $this->postJson('/api/v1/notices', [
            'title' => 'Hack',
            'body' => 'Nope',
            'audience_type' => 'all_active_members',
        ])->assertForbidden();
    }

    public function test_admin_can_create_preview_and_queue_publish_for_all_active_members(): void
    {
        Queue::fake();

        $admin = User::factory()->admin()->create();
        $active = User::factory()->member()->create();
        User::factory()->member()->inactive()->create();
        Sanctum::actingAs($admin);

        $create = $this->postJson('/api/v1/notices', [
            'title' => 'AGM notice',
            'body' => 'Meeting next week',
            'audience_type' => 'all_active_members',
            'publish_at' => now()->toDateTimeString(),
        ])->assertCreated();

        $noticeId = $create->json('data.id');

        $this->postJson('/api/v1/notices/'.$noticeId.'/preview')
            ->assertOk()
            ->assertJsonPath('data.recipient_count', 1);

        $this->postJson('/api/v1/notices/'.$noticeId.'/publish')
            ->assertOk()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.recipient_count', 1);

        Queue::assertPushed(PublishNoticeJob::class, fn (PublishNoticeJob $job) => $job->noticeId === $noticeId);

        // Preview counted only the active member (inactive excluded).
        $this->assertTrue($active->is_active);
    }

    public function test_selected_member_targeting_and_visibility(): void
    {
        $admin = User::factory()->admin()->create();
        $a = User::factory()->member()->create();
        $b = User::factory()->member()->create();

        $notice = app(NoticeService::class)->create($admin, [
            'title' => 'Private',
            'body' => 'Only A',
            'audience_type' => 'selected_members',
            'member_ids' => [$a->id],
        ]);
        app(NoticeService::class)->publish($admin, $notice);

        // Sync queue delivers via jobs.
        Sanctum::actingAs($a);
        $this->getJson('/api/v1/notices')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Private');

        Sanctum::actingAs($b);
        $this->getJson('/api/v1/notices')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/notices/'.$notice->id)->assertForbidden();
    }

    public function test_chunk_delivery_is_idempotent_on_retry(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();
        $notice = app(NoticeService::class)->create($admin, [
            'title' => 'Retry safe',
            'body' => 'Body',
            'audience_type' => 'selected_members',
            'member_ids' => [$member->id],
        ]);
        $notice = app(NoticeService::class)->publish($admin, $notice);

        $job = new DeliverNoticeChunkJob($notice->id, [$member->id]);
        $job->handle(app(NotificationService::class));
        $job->handle(app(NotificationService::class));

        $this->assertSame(1, UserNotification::query()->where('user_id', $member->id)->count());
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $member->id,
            'dedupe_key' => 'notice:'.$notice->id.':user:'.$member->id,
            'type' => AppNotificationType::Notice->value,
        ]);
    }

    public function test_unread_count_read_status_and_pagination(): void
    {
        $member = User::factory()->member()->create();
        $service = app(NotificationService::class);

        for ($i = 1; $i <= 3; $i++) {
            $service->notify(
                $member,
                AppNotificationType::DuesReminder,
                "Title $i",
                "Body $i",
                "dues:$i",
                sendPush: false,
            );
        }

        Sanctum::actingAs($member);
        $this->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 3);

        $page = $this->getJson('/api/v1/notifications?per_page=2')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.last_page', 2);

        $id = $page->json('data.0.id');
        $this->postJson('/api/v1/notifications/'.$id.'/read')
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        $this->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 2);

        $this->postJson('/api/v1/notifications/read-all')->assertOk();
        $this->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 0);
    }

    public function test_member_cannot_mark_another_users_notification_read(): void
    {
        $a = User::factory()->member()->create();
        $b = User::factory()->member()->create();
        $notification = app(NotificationService::class)->notify(
            $a,
            AppNotificationType::Notice,
            'Hi',
            'Body',
            'solo-a',
            sendPush: false,
        );

        Sanctum::actingAs($b);
        $this->postJson('/api/v1/notifications/'.$notification->id.'/read')->assertForbidden();
    }

    public function test_payment_recorded_dispatches_notification_job_once(): void
    {
        Queue::fake([NotifyPaymentRecordedJob::class]);

        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();
        $plan = app(ContributionPlanService::class)->createPlan($admin, [
            'name' => 'Std',
            'code' => 'STD',
            'default_amount' => '100.00',
        ]);
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 3, $plan->id, $member->id);

        $payment = app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '50.00',
            'method' => 'cash',
            'idempotency_key' => 'pay-notify-1',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '50.00'],
            ],
        ]);

        Queue::assertPushed(NotifyPaymentRecordedJob::class, 1);

        // Idempotent payment replay must not dispatch again.
        app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '50.00',
            'method' => 'cash',
            'idempotency_key' => 'pay-notify-1',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '50.00'],
            ],
        ]);

        Queue::assertPushed(NotifyPaymentRecordedJob::class, 1);

        (new NotifyPaymentRecordedJob($payment->id))->handle(app(NotificationService::class));
        (new NotifyPaymentRecordedJob($payment->id))->handle(app(NotificationService::class));

        $this->assertSame(1, UserNotification::query()
            ->where('user_id', $member->id)
            ->where('type', AppNotificationType::PaymentRecorded)
            ->count());
    }

    public function test_device_token_register_and_invalidate(): void
    {
        $member = User::factory()->member()->create();
        Sanctum::actingAs($member);

        $this->postJson('/api/v1/device-tokens', [
            'token' => 'fcm-token-abc',
            'platform' => 'android',
            'device_name' => 'Pixel',
        ])->assertCreated()
            ->assertJsonPath('push_configured', false);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $member->id,
            'token' => 'fcm-token-abc',
            'invalidated_at' => null,
        ]);

        $this->deleteJson('/api/v1/device-tokens', [
            'token' => 'fcm-token-abc',
        ])->assertOk();

        $this->assertNotNull(
            DeviceToken::query()->where('token', 'fcm-token-abc')->value('invalidated_at')
        );
    }

    public function test_publish_notice_job_chunks_without_loading_all_at_once(): void
    {
        Queue::fake();

        $admin = User::factory()->admin()->create();
        User::factory()->member()->count(3)->create();

        $notice = app(NoticeService::class)->create($admin, [
            'title' => 'Bulk',
            'body' => 'Hello',
            'audience_type' => 'all_active_members',
        ]);

        $notice->forceFill([
            'status' => 'published',
            'published_at' => now(),
            'recipient_count' => 3,
        ])->save();

        (new PublishNoticeJob($notice->id, chunkSize: 2))->handle(app(NoticeService::class));

        Queue::assertPushed(DeliverNoticeChunkJob::class, 2);
    }

    public function test_accountant_cannot_create_notices_but_can_list(): void
    {
        $accountant = User::factory()->accountant()->create();
        Sanctum::actingAs($accountant);

        $this->postJson('/api/v1/notices', [
            'title' => 'No',
            'body' => 'No',
            'audience_type' => 'all_active_members',
        ])->assertForbidden();

        $this->getJson('/api/v1/notices')->assertOk();
    }
}
