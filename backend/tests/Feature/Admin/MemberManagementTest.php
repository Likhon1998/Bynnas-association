<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Web member management UI retired — staff manage members via Flutter + API.
 */
class MemberManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_legacy_members_index_redirects_to_mobile_only_dashboard(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/members')
            ->assertRedirect('/dashboard');
    }

    public function test_member_cannot_access_legacy_member_admin_urls(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get('/members')
            ->assertRedirect(route('login'));
    }
}
