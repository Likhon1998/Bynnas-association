<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\DatabaseBackup;
use App\Services\Backup\DatabaseBackupService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class BackupController extends Controller
{
    public function __construct(
        private readonly DatabaseBackupService $backups,
    ) {}

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(UserRole::SuperAdmin), 403);

        return response()->json([
            'data' => DatabaseBackup::query()->latest('id')->limit(30)->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(UserRole::SuperAdmin), 403);

        try {
            $backup = $this->backups->create($request->user());
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => $backup,
            'message' => 'Database backup created.',
        ], 201);
    }
}
