<?php

namespace App\Console\Commands;

use App\Jobs\SendDuesReminderJob;
use Illuminate\Console\Command;

class SendDuesRemindersCommand extends Command
{
    protected $signature = 'notifications:dues-reminders
        {--period= : Period label YYYY-MM (defaults to current month)}
        {--monthly : Send monthly reminder type instead of outstanding-only}';

    protected $description = 'Queue chunked dues reminder / outstanding notifications for active members';

    public function handle(): int
    {
        $period = $this->option('period') ?: now()->format('Y-m');

        SendDuesReminderJob::dispatch(
            periodLabel: $period,
            outstandingOnly: ! $this->option('monthly'),
        );

        $this->info("Queued dues notifications for period {$period}.");

        return self::SUCCESS;
    }
}
