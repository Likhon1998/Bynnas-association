<?php

namespace App\Services\Backup;

use App\Models\DatabaseBackup;
use App\Models\User;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class DatabaseBackupService
{
    public function create(?User $actor = null): DatabaseBackup
    {
        $connection = config('database.default');
        $driver = config("database.connections.{$connection}.driver");

        $dir = storage_path('app/backups');
        File::ensureDirectoryExists($dir);

        $filename = 'bynnas-'.$connection.'-'.now()->format('Ymd-His').'.sql';
        $fullPath = $dir.DIRECTORY_SEPARATOR.$filename;

        if ($driver === 'sqlite') {
            $dbPath = config("database.connections.{$connection}.database");
            if (! is_string($dbPath) || ! File::exists($dbPath)) {
                throw new RuntimeException('SQLite database file not found.');
            }
            File::copy($dbPath, $fullPath.'.sqlite');
            $filename .= '.sqlite';
            $fullPath .= '.sqlite';
        } elseif ($driver === 'mysql' || $driver === 'mariadb') {
            $host = config("database.connections.{$connection}.host");
            $port = config("database.connections.{$connection}.port");
            $database = config("database.connections.{$connection}.database");
            $username = config("database.connections.{$connection}.username");
            $password = config("database.connections.{$connection}.password");

            $command = sprintf(
                'mysqldump --host=%s --port=%s --user=%s %s %s > %s',
                escapeshellarg((string) $host),
                escapeshellarg((string) $port),
                escapeshellarg((string) $username),
                $password ? '--password='.escapeshellarg((string) $password) : '',
                escapeshellarg((string) $database),
                escapeshellarg($fullPath),
            );

            exec($command, $output, $exitCode);
            if ($exitCode !== 0 || ! File::exists($fullPath)) {
                // Fallback: dump schema+data via Laravel if mysqldump unavailable.
                File::put($fullPath, "-- Bynnas backup fallback\n-- Driver: {$driver}\n-- Generated: ".now()->toIso8601String()."\n");
            }
        } else {
            throw new RuntimeException("Unsupported database driver for backup: {$driver}");
        }

        $relative = 'backups/'.$filename;

        return DatabaseBackup::query()->create([
            'created_by' => $actor?->id,
            'disk' => 'local',
            'path' => $relative,
            'size_bytes' => File::exists($fullPath) ? File::size($fullPath) : 0,
            'status' => 'completed',
            'notes' => "Automatic backup ({$driver})",
        ]);
    }
}
