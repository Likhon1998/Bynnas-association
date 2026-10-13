<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Web finance UI was retired in favour of the Flutter mobile app.
 */
class FinanceUiWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_staff_dashboard_shows_mobile_only_notice(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('mobile-only', false)
            ->assertSee('Flutter');
    }

    public function test_former_payment_urls_redirect_to_dashboard_notice(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/payments')
            ->assertRedirect('/dashboard');

        $this->actingAs($admin)
            ->get('/reports/member-wise')
            ->assertRedirect('/dashboard');
    }

    public function test_member_cannot_access_dashboard(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get('/dashboard')
            ->assertRedirect(route('login'));
    }
}
