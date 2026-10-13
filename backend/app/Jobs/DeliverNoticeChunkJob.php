<?php

namespace App\Jobs;

use App\Enums\AppNotificationType;
use App\Enums\NoticeStatus;
use App\Models\Notice;
use App\Models\User;
use App\Services\Notifications\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class DeliverNoticeChunkJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    /**
     * @param  list<int>  $userIds
     */
    public function __construct(
        public readonly int $noticeId,
        public readonly array $userIds,
    ) {}

    public function handle(NotificationService $notifications): void
    {
        $notice = Notice::query()->find($this->noticeId);
        if ($notice === null || $notice->status !== NoticeStatus::Published) {
            return;
        }

        User::query()
            ->whereIn('id', $this->userIds)
            ->where('is_active', true)
            ->orderBy('id')
            ->each(function (User $user) use ($notice, $notifications) {
                $notifications->notify(
                    user: $user,
                    type: AppNotificationType::Notice,
                    title: $notice->title,
                    body: $notice->body,
                    dedupeKey: sprintf('notice:%d:user:%d', $notice->id, $user->id),
                    data: [
                        'notice_id' => $notice->id,
                    ],
                    sendPush: true,
                );
            });
    }

    public function failed(\Throwable $e): void
    {
        Log::error('DeliverNoticeChunkJob failed', [
            'notice_id' => $this->noticeId,
            'user_count' => count($this->userIds),
            'error' => $e->getMessage(),
        ]);
    }
}
