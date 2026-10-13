<?php

namespace Tests\Feature\Api\V1;

use App\Enums\MemberDueStatus;
use App\Enums\PaymentStatus;
use App\Models\FinancialAuditLog;
use App\Models\MemberDue;
use App\Models\Payment;
use App\Models\User;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use App\Support\Money;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use LogicException;
use Tests\TestCase;

class FinanceTest extends TestCase
{
    use RefreshDatabase;

    private function seedPlanAndMember(string $defaultAmount = '500.00', ?string $override = null): array
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create();

        $plans = app(ContributionPlanService::class);
        $plan = $plans->createPlan($admin, [
            'name' => 'Standard Monthly',
            'code' => 'STANDARD',
            'default_amount' => $defaultAmount,
        ]);

        if ($override !== null) {
            $plans->assign($admin, [
                'user_id' => $member->id,
                'contribution_plan_id' => $plan->id,
                'amount' => $override,
                'effective_from' => '2026-01-01',
            ]);
        }

        return compact('admin', 'member', 'plan');
    }

    public function test_accountant_can_create_plan_and_member_cannot(): void
    {
        $accountant = User::factory()->accountant()->create();
        Sanctum::actingAs($accountant);

        $this->postJson('/api/v1/contribution-plans', [
            'name' => 'Standard',
            'code' => 'std',
            'default_amount' => '500.00',
        ])->assertCreated()
            ->assertJsonPath('data.code', 'STD')
            ->assertJsonPath('data.default_amount', '500.00');

        $member = User::factory()->member()->create();
        Sanctum::actingAs($member);

        $this->postJson('/api/v1/contribution-plans', [
            'name' => 'Hack',
            'code' => 'HACK',
            'default_amount' => '1.00',
        ])->assertForbidden();
    }

    public function test_due_generation_uses_assignment_override_and_is_idempotent(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('500.00', '300.00');
        Sanctum::actingAs($admin);

        $first = $this->postJson('/api/v1/dues/generate', [
            'year' => 2026,
            'month' => 3,
            'contribution_plan_id' => $plan->id,
            'user_id' => $member->id,
        ])->assertCreated();

        $first->assertJsonPath('data.created', 1)
            ->assertJsonPath('data.reused', 0)
            ->assertJsonPath('data.dues.0.amount_due', '300.00')
            ->assertJsonPath('data.dues.0.status', 'pending');

        $second = $this->postJson('/api/v1/dues/generate', [
            'year' => 2026,
            'month' => 3,
            'contribution_plan_id' => $plan->id,
            'user_id' => $member->id,
        ])->assertCreated();

        $second->assertJsonPath('data.created', 0)
            ->assertJsonPath('data.reused', 1);

        $this->assertSame(1, MemberDue::query()->count());
        $this->assertDatabaseHas('financial_audit_logs', [
            'action' => 'member_due.generated',
        ]);
    }

    public function test_partial_payment_allocation_updates_outstanding_and_status(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('500.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 3, $plan->id, $member->id);
        $due = $dues['dues'][0];

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '200.00',
            'method' => 'cash',
            'idempotency_key' => 'pay-partial-1',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '200.00'],
            ],
        ])->assertCreated();

        $response->assertJsonPath('data.amount', '200.00')
            ->assertJsonPath('data.status', 'posted')
            ->assertJsonStructure(['data' => ['receipt_number']]);

        $due->refresh();
        $this->assertSame('200.00', Money::normalize((string) $due->amount_allocated));
        $this->assertSame('300.00', $due->outstandingBalance());
        $this->assertSame(MemberDueStatus::Partial, $due->status);

        $this->getJson('/api/v1/balances/'.$member->id)
            ->assertOk()
            ->assertJsonPath('data.outstanding', '300.00');
    }

    public function test_payment_idempotency_returns_same_payment_without_double_allocation(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 4, $plan->id, $member->id);
        $due = $dues['dues'][0];
        Sanctum::actingAs($admin);

        $payload = [
            'user_id' => $member->id,
            'amount' => '100.00',
            'method' => 'cash',
            'idempotency_key' => 'idem-key-abc',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '100.00'],
            ],
        ];

        $first = $this->postJson('/api/v1/payments', $payload)->assertCreated();
        $second = $this->postJson('/api/v1/payments', $payload)->assertOk();

        $this->assertTrue($second->json('idempotent_replay'));
        $this->assertSame($first->json('data.id'), $second->json('data.id'));
        $this->assertSame($first->json('data.receipt_number'), $second->json('data.receipt_number'));
        $this->assertSame(1, Payment::query()->count());

        $due->refresh();
        $this->assertSame('100.00', Money::normalize((string) $due->amount_allocated));
        $this->assertSame(MemberDueStatus::Paid, $due->status);
    }

    public function test_allocation_cannot_exceed_payment_or_due_outstanding(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('50.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 5, $plan->id, $member->id);
        $due = $dues['dues'][0];
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '40.00',
            'method' => 'cash',
            'idempotency_key' => 'over-alloc-payment',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '45.00'],
            ],
        ])->assertStatus(422);

        $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '60.00',
            'method' => 'cash',
            'idempotency_key' => 'over-alloc-due',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '60.00'],
            ],
        ])->assertStatus(422);

        $this->assertSame(0, Payment::query()->count());
        $due->refresh();
        $this->assertSame('0.00', Money::normalize((string) $due->amount_allocated));
    }

    public function test_reversal_restores_due_balance_and_writes_audit(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('500.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 6, $plan->id, $member->id);
        $due = $dues['dues'][0];
        Sanctum::actingAs($admin);

        $paymentId = $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '200.00',
            'method' => 'bank_transfer',
            'idempotency_key' => 'rev-1',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '200.00'],
            ],
        ])->assertCreated()->json('data.id');

        $this->postJson('/api/v1/payments/'.$paymentId.'/reverse', [
            'reason' => 'Entered against wrong member',
        ])->assertOk()
            ->assertJsonPath('data.status', 'reversed');

        $due->refresh();
        $this->assertSame('0.00', Money::normalize((string) $due->amount_allocated));
        $this->assertSame(MemberDueStatus::Pending, $due->status);
        $this->assertSame(PaymentStatus::Reversed, Payment::query()->findOrFail($paymentId)->status);

        $this->assertDatabaseHas('financial_audit_logs', [
            'action' => 'payment.reversed',
            'entity_id' => $paymentId,
        ]);

        $this->postJson('/api/v1/payments/'.$paymentId.'/reverse', [
            'reason' => 'Again',
        ])->assertStatus(422);
    }

    public function test_member_can_view_own_finance_but_not_others(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $other = User::factory()->member()->create();
        app(DueService::class)->generateForPeriod($admin, 2026, 7, $plan->id, $member->id);

        Sanctum::actingAs($member);
        $this->getJson('/api/v1/dues')->assertOk()
            ->assertJsonCount(1, 'data')
            // SQLite may strip trailing zeros from DECIMAL casts; API must normalize.
            ->assertJsonPath('data.0.amount_due', '100.00')
            ->assertJsonPath('data.0.amount_allocated', '0.00')
            ->assertJsonPath('data.0.outstanding', '100.00');
        $this->getJson('/api/v1/balances/me')->assertOk()->assertJsonPath('data.outstanding', '100.00');
        $this->getJson('/api/v1/balances/'.$other->id)->assertForbidden();
        $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '10.00',
            'method' => 'cash',
            'idempotency_key' => 'member-cannot-pay',
        ])->assertForbidden();
    }

    public function test_inactive_member_cannot_receive_new_payments(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 8, $plan->id, $member->id);
        $due = $dues['dues'][0];
        $member->deactivate();

        Sanctum::actingAs($admin);
        $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '50.00',
            'method' => 'cash',
            'idempotency_key' => 'inactive-pay',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '50.00'],
            ],
        ])->assertStatus(422);
    }

    public function test_financial_records_cannot_be_hard_deleted(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 9, $plan->id, $member->id);
        $due = $dues['dues'][0];

        $payment = app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '40.00',
            'method' => 'cash',
            'idempotency_key' => 'no-delete',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '40.00'],
            ],
        ]);

        $this->expectException(LogicException::class);
        $payment->delete();
    }

    public function test_posted_payment_amount_is_not_editable_via_mass_update_path(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        Sanctum::actingAs($admin);

        // No update endpoint exists for payments — method not allowed.
        $this->putJson('/api/v1/payments/1', ['amount' => '1.00'])->assertStatus(405);

        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 10, $plan->id, $member->id);
        $payment = app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '25.00',
            'method' => 'cash',
            'idempotency_key' => 'no-edit',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '25.00'],
            ],
        ]);

        $this->assertSame('25.00', Money::normalize((string) $payment->fresh()->amount));
        $this->assertGreaterThan(0, FinancialAuditLog::query()->where('action', 'payment.posted')->count());
    }

    public function test_cannot_void_due_with_allocations(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 11, $plan->id, $member->id);
        $due = $dues['dues'][0];

        app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '10.00',
            'method' => 'cash',
            'idempotency_key' => 'void-block',
            'allocations' => [
                ['member_due_id' => $due->id, 'amount' => '10.00'],
            ],
        ]);

        Sanctum::actingAs($admin);
        $this->postJson('/api/v1/dues/'.$due->id.'/void', [
            'reason' => 'Mistake',
        ])->assertStatus(422);

        $due->refresh();
        $this->assertNotSame(MemberDueStatus::Voided, $due->status);
    }

    public function test_receipt_numbers_are_unique(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('100.00');
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 12, $plan->id, $member->id);
        $due = $dues['dues'][0];
        Sanctum::actingAs($admin);

        $r1 = $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '10.00',
            'method' => 'cash',
            'idempotency_key' => 'rcpt-1',
            'allocations' => [['member_due_id' => $due->id, 'amount' => '10.00']],
        ])->json('data.receipt_number');

        $r2 = $this->postJson('/api/v1/payments', [
            'user_id' => $member->id,
            'amount' => '15.00',
            'method' => 'cash',
            'idempotency_key' => 'rcpt-2',
            'allocations' => [['member_due_id' => $due->id, 'amount' => '15.00']],
        ])->json('data.receipt_number');

        $this->assertNotSame($r1, $r2);
        $this->assertMatchesRegularExpression('/^RCPT-\d{8}-\d{6}$/', $r1);
    }

    public function test_float_money_rejected_in_domain_helper(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        Money::normalize(10.5);
    }

    public function test_plan_default_used_when_no_assignment(): void
    {
        ['admin' => $admin, 'member' => $member, 'plan' => $plan] = $this->seedPlanAndMember('750.50');
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/dues/generate', [
            'year' => 2026,
            'month' => 1,
            'contribution_plan_id' => $plan->id,
            'user_id' => $member->id,
        ])->assertCreated()
            ->assertJsonPath('data.dues.0.amount_due', '750.50');
    }
}
