<?php

namespace App\Console\Commands;

use Database\Seeders\MobileIntegrationSeeder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;

/**
 * Prepares an isolated SQLite database for Flutter mobile integration tests.
 */
class PrepareMobileIntegrationCommand extends Command
{
    protected $signature = 'mobile-integration:prepare
        {--path= : sqlite path relative to backend root (default database/integration.sqlite)}
        {--fresh : Drop all tables before migrate}';

    protected $description = 'Migrate and seed the isolated mobile integration database';

    public function handle(): int
    {
        $relative = $this->option('path') ?: 'database/integration.sqlite';
        $absolute = base_path($relative);

        File::ensureDirectoryExists(dirname($absolute));
        if (! File::exists($absolute)) {
            File::put($absolute, '');
        }

        // Absolute path is required: `artisan serve` resolves relative DB paths
        // from the public/ CWD, which would miss database/integration.sqlite.
        putenv('DB_CONNECTION=sqlite');
        putenv('DB_DATABASE='.$absolute);
        $_ENV['DB_CONNECTION'] = 'sqlite';
        $_ENV['DB_DATABASE'] = $absolute;
        $_SERVER['DB_CONNECTION'] = 'sqlite';
        $_SERVER['DB_DATABASE'] = $absolute;

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => $absolute,
        ]);

        app('db')->purge();
        app('db')->reconnect();

        $migrateParams = [
            '--force' => true,
            '--database' => 'sqlite',
        ];

        if ($this->option('fresh')) {
            Artisan::call('migrate:fresh', $migrateParams);
        } else {
            Artisan::call('migrate', $migrateParams);
        }
        $this->line(trim(Artisan::output()));

        Artisan::call('db:seed', [
            '--class' => MobileIntegrationSeeder::class,
            '--force' => true,
            '--database' => 'sqlite',
        ]);

        $this->info('Mobile integration database ready: '.$absolute);
        $this->line('Member: '.env('INTEGRATION_MEMBER_EMAIL', 'integration.member@bynnas.test'));
        $this->line('Other:  '.env('INTEGRATION_OTHER_MEMBER_EMAIL', 'integration.other@bynnas.test'));

        return self::SUCCESS;
    }
}
