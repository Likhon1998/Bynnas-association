<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Web notices UI retired — staff manage notices via Flutter + API.
 */
class NoticeManagementWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_legacy_notices_index_redirects_to_mobile_only_dashboard(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)
            ->get('/notices')
            ->assertRedirect('/dashboard');
    }

    public function test_member_cannot_access_legacy_web_notices(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get('/notices')
            ->assertRedirect(route('login'));
    }
}
