<?php

namespace App\Console\Commands;

use App\Services\Backup\DatabaseBackupService;
use Illuminate\Console\Command;

class BackupDatabaseCommand extends Command
{
    protected $signature = 'bynnas:backup-database';

    protected $description = 'Create a local database backup under storage/app/backups';

    public function handle(DatabaseBackupService $backups): int
    {
        $backup = $backups->create();
        $this->info("Backup created: {$backup->path} ({$backup->size_bytes} bytes)");

        return self::SUCCESS;
    }
}
