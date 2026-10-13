<?php

namespace Tests\Feature\Admin;

use App\Enums\PaymentStatus;
use App\Models\Payment;
use App\Models\User;
use App\Services\Finance\ContributionPlanService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FinanceUiWebTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array{0: User, 1: User, 2: Payment}
     */
    private function seedPaymentFixture(): array
    {
        $admin = User::factory()->admin()->create();
        $member = User::factory()->member()->create([
            'name' => 'Finance UI Member',
            'member_id' => 'BYN-UI-0001',
        ]);

        $plan = app(ContributionPlanService::class)->createPlan($admin, [
            'name' => 'Standard',
            'code' => 'STD-UI',
            'default_amount' => '100.00',
        ]);
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 4, $plan->id, $member->id);
        $payment = app(PaymentService::class)->post($admin, [
            'user_id' => $member->id,
            'amount' => '40.00',
            'method' => 'cash',
            'received_at' => '2026-04-10 09:00:00',
            'idempotency_key' => 'finance-ui-pay-1',
            'allocations' => [
                ['member_due_id' => $dues['dues'][0]->id, 'amount' => '40.00'],
            ],
        ]);

        return [$admin, $member, $payment];
    }

    public function test_staff_can_access_payments_receipt_statement_and_registers(): void
    {
        [$admin, $member, $payment] = $this->seedPaymentFixture();

        $this->actingAs($admin)
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('Collection rate')
            ->assertSee('Recent payments')
            ->assertSee($payment->receipt_number);

        $this->actingAs($admin)
            ->get('/payments')
            ->assertOk()
            ->assertSee('Payments')
            ->assertSee($payment->receipt_number);

        $this->actingAs($admin)
            ->get('/payments/'.$payment->id)
            ->assertOk()
            ->assertSee('40.00')
            ->assertSee('Allocations');

        $this->actingAs($admin)
            ->get('/receipts/'.$payment->id)
            ->assertOk()
            ->assertSee($payment->receipt_number)
            ->assertSee('Finance UI Member');

        $this->actingAs($admin)
            ->get('/receipts/'.$payment->id.'/pdf')
            ->assertOk();

        $this->actingAs($admin)
            ->get('/members/'.$member->id)
            ->assertOk()
            ->assertSee('Outstanding')
            ->assertSee('Monthly contribution status');

        $this->actingAs($admin)
            ->get('/members/'.$member->id.'/statement')
            ->assertOk()
            ->assertSee('Member statement')
            ->assertSee('100.00');

        $this->actingAs($admin)
            ->get('/members/'.$member->id.'/statement/pdf')
            ->assertOk();

        $this->actingAs($admin)
            ->get('/reports/payment-register')
            ->assertOk()
            ->assertSee('Payment & receipt register');

        $this->actingAs($admin)
            ->get('/reports/member-wise/csv')
            ->assertOk();

        $this->actingAs($admin)
            ->get('/reports/month-wise/csv')
            ->assertOk();
    }

    public function test_member_cannot_access_admin_finance_pages(): void
    {
        [, $member, $payment] = $this->seedPaymentFixture();

        $this->actingAs($member)
            ->get('/payments')
            ->assertRedirect(route('login'));

        $this->actingAs($member)
            ->get('/receipts/'.$payment->id)
            ->assertRedirect(route('login'));
    }

    public function test_recording_payment_uses_idempotency_and_shows_validation_errors(): void
    {
        [$admin, $member] = $this->seedPaymentFixture();

        $plan = app(ContributionPlanService::class)->createPlan($admin, [
            'name' => 'Extra',
            'code' => 'EXTRA',
            'default_amount' => '50.00',
        ]);
        $dues = app(DueService::class)->generateForPeriod($admin, 2026, 5, $plan->id, $member->id);

        $payload = [
            'user_id' => $member->id,
            'amount' => '25.00',
            'method' => 'cash',
            'idempotency_key' => 'web-idempotent-1',
            'allocations' => [
                [
                    'member_due_id' => $dues['dues'][0]->id,
                    'amount' => '25.00',
                ],
            ],
        ];

        $first = $this->actingAs($admin)->post('/payments', $payload);
        $first->assertRedirect();
        $paymentId = (int) basename(parse_url($first->headers->get('Location'), PHP_URL_PATH));

        $second = $this->actingAs($admin)->post('/payments', $payload);
        $second->assertRedirect(route('payments.show', $paymentId));
        $second->assertSessionHas('status');

        $this->actingAs($admin)
            ->post('/payments', [
                'user_id' => $member->id,
                'amount' => '0',
                'method' => 'cash',
                'idempotency_key' => 'web-bad-amount',
            ])
            ->assertSessionHasErrors('amount');
    }

    public function test_reversed_payment_is_marked_on_receipt_and_register(): void
    {
        [$admin, , $payment] = $this->seedPaymentFixture();

        app(PaymentService::class)->reverse($admin, $payment, 'Correction entry');

        $this->actingAs($admin)
            ->get('/receipts/'.$payment->id)
            ->assertOk()
            ->assertSee('REVERSED')
            ->assertSee('Correction entry');

        $this->actingAs($admin)
            ->get('/reports/reversed-payments')
            ->assertOk()
            ->assertSee($payment->receipt_number)
            ->assertSee('Correction entry');

        $this->assertSame(PaymentStatus::Reversed, $payment->fresh()->status);
    }
}
