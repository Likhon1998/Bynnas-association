<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StatementTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_own_statement_but_not_another_members(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();
        $other = User::factory()->member()->create();

        $plan = app(ContributionPlanService::class)->createPlan($admin, [
            'name' => 'Standard',
            'code' => 'STMT',
            'default_amount' => '200.00',
        ]);
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 6, $plan->id, $member->id);
        app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '50.00',
            'method' => 'cash',
            'idempotency_key' => 'stmt-pay',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '50.00'],
            ],
        ]);

        Sanctum::actingAs($member);
        $this->getJson('/api/v1/statements/me')
            ->assertOk()
            ->assertJsonPath('data.summary.expected_dues', '200.00')
            ->assertJsonPath('data.summary.total_paid', '50.00')
            ->assertJsonPath('data.summary.outstanding', '150.00');

        $this->getJson('/api/v1/statements/'.$other->id)->assertForbidden();

        Sanctum::actingAs($other);
        $this->getJson('/api/v1/statements/'.$member->id)->assertForbidden();
    }

    public function test_dashboard_includes_collection_rate_and_month_snapshots(): void
    {
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'collection_rate',
                    'current_month' => ['expected_dues', 'actual_collections', 'outstanding'],
                    'previous_month' => ['expected_dues', 'actual_collections', 'outstanding'],
                    'recent_payments',
                ],
            ]);
    }
}
