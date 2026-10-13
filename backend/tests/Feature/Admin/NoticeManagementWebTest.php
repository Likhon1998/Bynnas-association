<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NoticeManagementWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_manage_notices_in_web_panel(): void
    {
        $admin = User::factory()->admin()->create();
        User::factory()->member()->create();

        $this->actingAs($admin)
            ->get(route('notices.index'))
            ->assertOk()
            ->assertSee('Notices');

        $this->actingAs($admin)
            ->post(route('notices.store'), [
                'title' => 'Web AGM',
                'body' => 'Please attend',
                'audience_type' => 'all_active_members',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('notices', [
            'title' => 'Web AGM',
            'status' => 'draft',
        ]);
    }

    public function test_member_cannot_access_web_notices(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get(route('notices.index'))
            ->assertRedirect(route('login'));
    }
}
