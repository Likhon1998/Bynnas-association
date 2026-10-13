<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use App\Policies\MemberPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MemberTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_member_with_unique_member_id(): void
    {
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/members', [
            'name' => 'Asha Rahman',
            'email' => 'asha@example.com',
            'phone' => '+8801711111111',
            'address' => 'Chittagong',
            'joined_on' => '2026-01-15',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.name', 'Asha Rahman')
            ->assertJsonPath('data.email', 'asha@example.com')
            ->assertJsonPath('data.role', 'member')
            ->assertJsonPath('data.phone', '+8801711111111')
            ->assertJsonStructure(['data' => ['member_id'], 'temporary_password']);

        $this->assertDatabaseHas('users', [
            'email' => 'asha@example.com',
            'role' => 'member',
        ]);
        $this->assertDatabaseHas('member_profiles', [
            'phone' => '+8801711111111',
            'address' => 'Chittagong',
        ]);
        $this->assertNotNull($response->json('data.member_id'));
    }

    public function test_member_ids_increment_safely(): void
    {
        User::factory()->member('BYN-2026-0007')->create();
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/members', [
            'name' => 'Next Member',
            'email' => 'next@example.com',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.member_id', 'BYN-2026-0008');
    }

    public function test_staff_can_search_and_paginate_members(): void
    {
        User::factory()->member('BYN-2026-0100')->create(['name' => 'Alpha Member', 'email' => 'alpha@example.com']);
        User::factory()->member('BYN-2026-0101')->create(['name' => 'Beta Member', 'email' => 'beta@example.com']);
        $accountant = User::factory()->accountant()->create();
        Sanctum::actingAs($accountant);

        $response = $this->getJson('/api/v1/members?search=Alpha&per_page=10');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Alpha Member')
            ->assertJsonStructure(['meta' => ['current_page', 'total']]);
    }

    public function test_member_can_view_own_profile_but_not_list(): void
    {
        $member = User::factory()->member()->create();
        $member->memberProfile()->create(['phone' => '01700000000']);
        Sanctum::actingAs($member);

        $this->getJson('/api/v1/members/me')
            ->assertOk()
            ->assertJsonPath('data.email', $member->email)
            ->assertJsonPath('data.phone', '01700000000');

        $this->getJson('/api/v1/members')->assertForbidden();
    }

    public function test_member_cannot_view_another_member(): void
    {
        $member = User::factory()->member()->create();
        $other = User::factory()->member()->create();
        Sanctum::actingAs($member);

        $this->getJson('/api/v1/members/'.$other->id)->assertForbidden();
    }

    public function test_admin_can_deactivate_and_reactivate_without_deleting(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();
        $member->createToken('device');
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/members/'.$member->id.'/deactivate')
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('users', [
            'id' => $member->id,
            'is_active' => false,
        ]);
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->postJson('/api/v1/members/'.$member->id.'/reactivate')
            ->assertOk()
            ->assertJsonPath('data.is_active', true);
    }

    public function test_accountant_cannot_create_or_deactivate_members(): void
    {
        $accountant = User::factory()->accountant()->create();
        $member = User::factory()->member()->create();
        Sanctum::actingAs($accountant);

        $this->postJson('/api/v1/members', [
            'name' => 'Blocked',
            'email' => 'blocked@example.com',
        ])->assertForbidden();

        $this->postJson('/api/v1/members/'.$member->id.'/deactivate')
            ->assertForbidden();
    }

    public function test_members_cannot_be_hard_deleted_via_policy(): void
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();

        $this->assertFalse($admin->can('delete', $member) || app(MemberPolicy::class)->delete($admin, $member));
    }
}
