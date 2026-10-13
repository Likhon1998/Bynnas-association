<?php

namespace Tests\Feature\Api\V1;

use App\Models\MemberDue;
use App\Models\User;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use App\Services\Finance\ReportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportDashboardTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Known fixture:
     * - Plan default 500.00
     * - Member A override 300.00, Member B default 500.00
     * - March 2026 dues → expected 800.00
     * - Payment 200.00 allocated to A → collections 200, allocated 200, outstanding 600
     * - Status: A partial, B pending
     *
     * @return array{admin: User, memberA: User, memberB: User, expected: string, collections: string, outstanding: string}
     */
    private function seedKnownFixture(): array
    {
        $admin = User::factory()->admin()->create();
        $memberA = User::factory()->member('BYN-2026-1001')->create(['name' => 'Member Alpha']);
        $memberB = User::factory()->member('BYN-2026-1002')->create(['name' => 'Member Beta']);

        $plans = app(ContributionPlanService::class);
        $plan = $plans->createPlan($admin, [
            'name' => 'Standard Monthly',
            'code' => 'STANDARD',
            'default_amount' => '500.00',
        ]);
        $plans->assign($admin, [
            'user_id' => $memberA->id,
            'contribution_plan_id' => $plan->id,
            'amount' => '300.00',
            'effective_from' => '2026-01-01',
        ]);

        $dues = app(DueService::class);
        $dues->generateForPeriod($admin, 2026, 3, $plan->id, $memberA->id);
        $dues->generateForPeriod($admin, 2026, 3, $plan->id, $memberB->id);

        $dueA = MemberDue::query()->where('user_id', $memberA->id)->firstOrFail();

        app(PaymentService::class)->post($admin, [
            'user_id' => $memberA->id,
            'amount' => '200.00',
            'method' => 'cash',
            'received_at' => '2026-03-15 10:00:00',
            'idempotency_key' => 'fixture-pay-1',
            'allocations' => [
                ['member_due_id' => $dueA->id, 'amount' => '200.00'],
            ],
        ]);

        return [
            'admin' => $admin,
            'memberA' => $memberA,
            'memberB' => $memberB,
            'expected' => '800.00',
            'collections' => '200.00',
            'outstanding' => '600.00',
            'allocated' => '200.00',
        ];
    }

    public function test_dashboard_totals_match_known_fixture(): void
    {
        $fixture = $this->seedKnownFixture();
        Sanctum::actingAs($fixture['admin']);

        $response = $this->getJson('/api/v1/dashboard?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertJsonPath('data.active_members', 2)
            ->assertJsonPath('data.expected_dues', $fixture['expected'])
            ->assertJsonPath('data.actual_collections', $fixture['collections'])
            ->assertJsonPath('data.allocated_to_dues', $fixture['allocated'])
            ->assertJsonPath('data.outstanding', $fixture['outstanding'])
            ->assertJsonPath('data.payment_status.pending', 1)
            ->assertJsonPath('data.payment_status.partial', 1)
            ->assertJsonPath('data.payment_status.paid', 0);

        $this->assertSame('admin', $response->json('data.role'));
        $this->assertContains('manage_members', $response->json('data.capabilities'));
    }

    public function test_report_service_totals_match_fixture_independently_of_http(): void
    {
        $fixture = $this->seedKnownFixture();
        $summary = app(ReportService::class)->dashboardSummary('2026-03-01', '2026-03-31');

        $this->assertSame($fixture['expected'], $summary['expected_dues']);
        $this->assertSame($fixture['collections'], $summary['actual_collections']);
        $this->assertSame($fixture['outstanding'], $summary['outstanding']);
        $this->assertSame(2, $summary['active_members']);
    }

    public function test_member_wise_summary_is_full_filter_not_page_slice(): void
    {
        $fixture = $this->seedKnownFixture();
        Sanctum::actingAs($fixture['admin']);

        $response = $this->getJson('/api/v1/reports/member-wise?from=2026-03-01&to=2026-03-31&per_page=1')
            ->assertOk()
            ->assertJsonPath('summary.expected_dues', '800.00')
            ->assertJsonPath('summary.actual_collections', '200.00')
            ->assertJsonPath('summary.outstanding', '600.00')
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.total', 2)
            ->assertJsonCount(1, 'data');

        $row = collect($response->json('data'))->firstWhere('member_id', 'BYN-2026-1001');
        if ($row === null) {
            // Page 1 may be Alpha or Beta depending on name sort; fetch page containing Alpha via search.
            $row = $this->getJson('/api/v1/reports/member-wise?search=Alpha&from=2026-03-01&to=2026-03-31')
                ->assertOk()
                ->json('data.0');
        }

        $this->assertSame('300.00', $row['expected_dues']);
        $this->assertSame('200.00', $row['actual_collections']);
        $this->assertSame('100.00', $row['outstanding']);
    }

    public function test_month_wise_report_totals_match_fixture(): void
    {
        $fixture = $this->seedKnownFixture();
        Sanctum::actingAs($fixture['admin']);

        $this->getJson('/api/v1/reports/month-wise?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertJsonPath('summary.expected_dues', '800.00')
            ->assertJsonPath('summary.actual_collections', '200.00')
            ->assertJsonPath('summary.outstanding', '600.00')
            ->assertJsonPath('data.0.label', '2026-03')
            ->assertJsonPath('data.0.expected_dues', '800.00')
            ->assertJsonPath('data.0.actual_collections', '200.00');
    }

    public function test_accountant_dashboard_is_financial_focused_and_member_is_scoped(): void
    {
        $fixture = $this->seedKnownFixture();

        $accountant = User::factory()->accountant()->create();
        Sanctum::actingAs($accountant);
        $this->getJson('/api/v1/dashboard?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertJsonPath('data.role', 'accountant')
            ->assertJsonPath('data.expected_dues', '800.00')
            ->assertJsonPath('data.headline', 'Collections & outstanding');

        Sanctum::actingAs($fixture['memberA']);
        $this->getJson('/api/v1/dashboard?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertJsonPath('data.role', 'member')
            ->assertJsonPath('data.expected_dues', '300.00')
            ->assertJsonPath('data.actual_collections', '200.00')
            ->assertJsonPath('data.outstanding', '100.00')
            ->assertJsonPath('data.active_members', 1);
    }

    public function test_member_cannot_access_staff_reports_or_pdf(): void
    {
        $fixture = $this->seedKnownFixture();
        Sanctum::actingAs($fixture['memberA']);

        $this->getJson('/api/v1/reports/member-wise')->assertForbidden();
        $this->getJson('/api/v1/reports/month-wise')->assertForbidden();
        $this->get('/api/v1/reports/member-wise/pdf')->assertForbidden();
    }

    public function test_staff_can_export_pdf(): void
    {
        $fixture = $this->seedKnownFixture();
        Sanctum::actingAs($fixture['admin']);

        $this->get('/api/v1/reports/member-wise/pdf?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf');

        $this->get('/api/v1/reports/month-wise/pdf?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf');
    }

    public function test_reversed_payment_excluded_from_collections(): void
    {
        $fixture = $this->seedKnownFixture();
        $admin = $fixture['admin'];

        $dueB = MemberDue::query()->where('user_id', $fixture['memberB']->id)->firstOrFail();
        $payment = app(PaymentService::class)->post($admin, [
            'user_id' => $fixture['memberB']->id,
            'amount' => '500.00',
            'method' => 'cash',
            'received_at' => '2026-03-20 12:00:00',
            'idempotency_key' => 'fixture-pay-reverse',
            'allocations' => [
                ['member_due_id' => $dueB->id, 'amount' => '500.00'],
            ],
        ]);
        app(PaymentService::class)->reverse($admin, $payment, 'Fixture reversal');

        Sanctum::actingAs($admin);
        $this->getJson('/api/v1/dashboard?from=2026-03-01&to=2026-03-31')
            ->assertOk()
            ->assertJsonPath('data.actual_collections', '200.00')
            ->assertJsonPath('data.outstanding', '600.00');
    }
}
