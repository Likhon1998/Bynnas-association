<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_login_and_receive_token(): void
    {
        $user = User::factory()->member('BYN-2026-0001')->create([
            'email' => 'member@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'member@example.com',
            'password' => 'password',
            'device_name' => 'test-device',
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'token',
                'token_type',
                'user' => ['id', 'name', 'email', 'role', 'member_id', 'is_active'],
            ])
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.email', $user->email)
            ->assertJsonPath('user.role', 'member')
            ->assertJsonPath('user.member_id', 'BYN-2026-0001');

        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_login_fails_with_invalid_credentials(): void
    {
        User::factory()->member()->create([
            'email' => 'member@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'member@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->member()->inactive()->create([
            'email' => 'inactive@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'inactive@example.com',
            'password' => 'password',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->member('BYN-2026-0042')->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/auth/me');

        $response->assertOk()
            ->assertJsonPath('data.email', $user->email)
            ->assertJsonPath('data.member_id', 'BYN-2026-0042');
    }

    public function test_inactive_token_is_rejected_and_revoked(): void
    {
        $user = User::factory()->member()->create();
        $token = $user->createToken('test-device')->plainTextToken;

        $user->forceFill([
            'is_active' => false,
            'deactivated_at' => now(),
        ])->save();

        $response = $this->withToken($token)
            ->getJson('/api/v1/auth/me');

        $response->assertForbidden()
            ->assertJsonPath('message', 'This account has been deactivated.');

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_authenticated_user_can_logout(): void
    {
        $user = User::factory()->member()->create();
        $token = $user->createToken('test-device')->plainTextToken;

        $response = $this->withToken($token)
            ->postJson('/api/v1/auth/logout');

        $response->assertOk()
            ->assertJsonPath('message', 'Logged out successfully.');

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_authenticated_user_can_logout_all_devices(): void
    {
        $user = User::factory()->member()->create();
        $user->createToken('device-a');
        $token = $user->createToken('device-b')->plainTextToken;

        $this->assertDatabaseCount('personal_access_tokens', 2);

        $response = $this->withToken($token)
            ->postJson('/api/v1/auth/logout-all');

        $response->assertOk()
            ->assertJsonPath('message', 'Logged out from all devices successfully.');

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_forgot_password_sends_reset_link(): void
    {
        Notification::fake();

        $user = User::factory()->member()->create([
            'email' => 'member@example.com',
        ]);

        $response = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'member@example.com',
        ]);

        $response->assertOk();
        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function test_password_can_be_reset_and_tokens_revoked(): void
    {
        Notification::fake();

        $user = User::factory()->member()->create([
            'email' => 'member@example.com',
            'password' => 'password',
        ]);
        $user->createToken('old-device');

        $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'member@example.com',
        ]);

        $token = null;
        Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $notification) use (&$token) {
            $token = $notification->token;

            return true;
        });

        $response = $this->postJson('/api/v1/auth/reset-password', [
            'token' => $token,
            'email' => 'member@example.com',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'member@example.com',
            'password' => 'new-password',
        ]);

        $login->assertOk()->assertJsonStructure(['token']);
    }

    public function test_staff_can_access_staff_ping(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/staff/ping')
            ->assertOk()
            ->assertJsonPath('message', 'Staff access granted.');
    }

    public function test_member_cannot_access_staff_ping(): void
    {
        $member = User::factory()->member()->create();

        $this->actingAs($member, 'sanctum')
            ->getJson('/api/v1/staff/ping')
            ->assertForbidden();
    }
}
