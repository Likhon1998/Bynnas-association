<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportDashboardWebTest extends TestCase
{
    use RefreshDatabase;

    private function seedFixture(): User
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();

        $plans = app(ContributionPlanService::class);
        $plan = $plans->createPlan($admin, [
            'name' => 'Standard',
            'code' => 'STD',
            'default_amount' => '100.00',
        ]);
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 3, $plan->id, $member->id);
        app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '40.00',
            'method' => 'cash',
            'received_at' => '2026-03-10 09:00:00',
            'idempotency_key' => 'web-fixture',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '40.00'],
            ],
        ]);

        return $admin;
    }

    public function test_admin_dashboard_shows_server_totals(): void
    {
        $admin = $this->seedFixture();

        $this->actingAs($admin)
            ->get('/dashboard?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertSee('Admin overview')
            ->assertSee('100.00')
            ->assertSee('40.00')
            ->assertSee('60.00');
    }

    public function test_accountant_dashboard_variant(): void
    {
        $this->seedFixture();
        $accountant = User::factory()->accountant()->create();

        $this->actingAs($accountant)
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('Collections & outstanding');
    }

    public function test_staff_can_view_reports_print_and_pdf(): void
    {
        $admin = $this->seedFixture();

        $this->actingAs($admin)
            ->get('/reports/member-wise?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertSee('Member-wise report')
            ->assertSee('Summary totals are computed on the server');

        $this->actingAs($admin)
            ->get('/reports/month-wise?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertSee('Month-wise report')
            ->assertSee('2026-03');

        $this->actingAs($admin)
            ->get('/reports/member-wise?print=1&from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertSee('Member-wise contribution report');

        $this->actingAs($admin)
            ->get('/reports/member-wise/pdf?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf');
    }

    public function test_member_cannot_access_web_reports(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get('/dashboard')
            ->assertRedirect(route('login'));

        $member = User::factory()->member()->create();
        $this->actingAs($member)
            ->get('/reports/member-wise')
            ->assertRedirect(route('login'));
    }
}
