<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Web report dashboards were retired; staff use the Flutter app + API.
 */
class ReportDashboardWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dashboard_is_mobile_only_notice(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('Flutter app');
    }

    public function test_accountant_sees_same_mobile_only_notice(): void
    {
        $accountant = User::factory()->accountant()->create();

        $this->actingAs($accountant)
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('mobile-only', false);
    }

    public function test_legacy_report_paths_redirect(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/reports/month-wise')
            ->assertRedirect('/dashboard');
    }

    public function test_member_cannot_access_web_reports(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get('/dashboard')
            ->assertRedirect(route('login'));

        $this->actingAs($member)
            ->get('/reports/member-wise')
            ->assertRedirect(route('login'));
    }
}
