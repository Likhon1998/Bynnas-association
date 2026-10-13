<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MemberManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_members_index(): void
    {
        $admin = User::factory()->admin()->create();
        User::factory()->member()->create(['name' => 'Listed Member']);

        $this->actingAs($admin)
            ->get(route('members.index'))
            ->assertOk()
            ->assertSee('Listed Member')
            ->assertSee('Add member');
    }

    public function test_admin_can_create_member_via_web(): void
    {
        $admin = User::factory()->admin()->create();

        $response = $this->actingAs($admin)->post(route('members.store'), [
            'name' => 'Web Member',
            'email' => 'web-member@example.com',
            'phone' => '01800000000',
            'joined_on' => '2026-02-01',
        ]);

        $member = User::query()->where('email', 'web-member@example.com')->first();
        $this->assertNotNull($member);
        $response->assertRedirect(route('members.show', $member));
        $this->assertDatabaseHas('member_profiles', [
            'user_id' => $member->id,
            'phone' => '01800000000',
        ]);
    }

    public function test_member_cannot_access_admin_member_pages(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member)
            ->get(route('members.index'))
            ->assertRedirect(route('login'));
    }

    public function test_admin_can_deactivate_member_from_web(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();

        $this->actingAs($admin)
            ->post(route('members.deactivate', $member))
            ->assertRedirect();

        $this->assertFalse($member->fresh()->is_active);
        $this->assertDatabaseHas('users', ['id' => $member->id]);
    }
}
