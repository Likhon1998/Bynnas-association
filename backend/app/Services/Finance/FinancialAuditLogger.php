<?php

namespace App\Services\Finance;

use App\Models\FinancialAuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class FinancialAuditLogger
{
    /**
     * @param  array<string, mixed>|null  $before
     * @param  array<string, mixed>|null  $after
     * @param  array<string, mixed>|null  $meta
     */
    public function log(
        ?User $actor,
        string $action,
        Model $entity,
        ?array $before = null,
        ?array $after = null,
        ?array $meta = null,
    ): FinancialAuditLog {
        return FinancialAuditLog::query()->create([
            'actor_id' => $actor?->id,
            'action' => $action,
            'entity_type' => $entity::class,
            'entity_id' => $entity->getKey(),
            'before' => $before,
            'after' => $after,
            'meta' => $meta,
            'created_at' => now(),
        ]);
    }
}
