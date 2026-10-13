<?php

namespace App\Jobs;

use App\Enums\NoticeStatus;
use App\Models\Notice;
use App\Services\Notices\NoticeService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class PublishNoticeJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(
        public readonly int $noticeId,
        public readonly int $chunkSize = 200,
    ) {}

    public function handle(NoticeService $notices): void
    {
        $notice = Notice::query()->find($this->noticeId);
        if ($notice === null || $notice->status !== NoticeStatus::Published) {
            Log::info('PublishNoticeJob skipped', ['notice_id' => $this->noticeId]);

            return;
        }

        $notices->recipientQuery($notice)
            ->select('id')
            ->chunkById($this->chunkSize, function ($users) use ($notice) {
                $ids = $users->pluck('id')->map(fn ($id) => (int) $id)->all();
                DeliverNoticeChunkJob::dispatch($notice->id, $ids);
            });
    }

    public function failed(\Throwable $e): void
    {
        Log::error('PublishNoticeJob failed', [
            'notice_id' => $this->noticeId,
            'error' => $e->getMessage(),
        ]);
    }
}
