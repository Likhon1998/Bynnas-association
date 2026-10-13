<?php

namespace App\Jobs;

use App\Enums\AppNotificationType;
use App\Enums\MemberDueStatus;
use App\Enums\UserRole;
use App\Models\MemberDue;
use App\Models\User;
use App\Services\Notifications\NotificationService;
use App\Support\Money;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

/**
 * Chunked monthly dues / outstanding reminders. Dispatch once per run (scheduler/command).
 */
class SendDuesReminderJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 2;

    public function __construct(
        public readonly string $periodLabel,
        public readonly int $chunkSize = 200,
        public readonly bool $outstandingOnly = true,
    ) {}

    public function handle(NotificationService $notifications): void
    {
        User::query()
            ->where('role', UserRole::Member)
            ->where('is_active', true)
            ->orderBy('id')
            ->chunkById($this->chunkSize, function ($members) use ($notifications) {
                foreach ($members as $member) {
                    $dues = MemberDue::query()
                        ->with('period')
                        ->where('user_id', $member->id)
                        ->whereIn('status', [
                            MemberDueStatus::Pending,
                            MemberDueStatus::Partial,
                        ])
                        ->whereHas('period', fn ($q) => $q->where('label', $this->periodLabel))
                        ->get();

                    if ($dues->isEmpty()) {
                        continue;
                    }

                    $outstanding = Money::normalize('0');
                    foreach ($dues as $due) {
                        $outstanding = Money::add($outstanding, $due->outstandingBalance());
                    }

                    if ($this->outstandingOnly && ! Money::isPositive($outstanding)) {
                        continue;
                    }

                    $type = $this->outstandingOnly
                        ? AppNotificationType::OutstandingDues
                        : AppNotificationType::DuesReminder;

                    $notifications->notify(
                        user: $member,
                        type: $type,
                        title: $this->outstandingOnly ? 'Outstanding dues' : 'Monthly contribution reminder',
                        body: sprintf(
                            'You have %s BDT outstanding for %s.',
                            $outstanding,
                            $this->periodLabel,
                        ),
                        dedupeKey: sprintf(
                            '%s:%d:%s',
                            $type->value,
                            $member->id,
                            $this->periodLabel,
                        ),
                        data: [
                            'period' => $this->periodLabel,
                            'outstanding' => $outstanding,
                        ],
                    );
                }
            });
    }

    public function failed(\Throwable $e): void
    {
        Log::error('SendDuesReminderJob failed', [
            'period' => $this->periodLabel,
            'error' => $e->getMessage(),
        ]);
    }
}
