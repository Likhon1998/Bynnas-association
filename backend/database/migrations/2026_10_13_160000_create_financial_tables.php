<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contribution_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code', 64)->unique();
            $table->text('description')->nullable();
            $table->decimal('default_amount', 15, 2);
            $table->char('currency', 3)->default('BDT');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('member_contribution_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('contribution_plan_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2)->nullable();
            $table->date('effective_from');
            $table->date('effective_to')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(
                ['user_id', 'contribution_plan_id', 'effective_from'],
                'member_plan_effective_unique'
            );
            $table->index(['user_id', 'is_active']);
        });

        Schema::create('due_periods', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('year');
            $table->unsignedTinyInteger('month');
            $table->string('label', 16);
            $table->date('starts_on');
            $table->date('ends_on');
            $table->timestamps();

            $table->unique(['year', 'month']);
            $table->unique('label');
        });

        Schema::create('member_dues', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('due_period_id')->constrained()->cascadeOnDelete();
            $table->foreignId('contribution_plan_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount_due', 15, 2);
            $table->decimal('amount_allocated', 15, 2)->default(0);
            $table->string('status', 20)->default('pending');
            $table->char('currency', 3)->default('BDT');
            $table->string('idempotency_key', 100)->nullable()->unique();
            $table->timestamp('voided_at')->nullable();
            $table->foreignId('voided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('void_reason', 500)->nullable();
            $table->timestamps();

            $table->unique(
                ['user_id', 'due_period_id', 'contribution_plan_id'],
                'member_due_unique'
            );
            $table->index(['user_id', 'status']);
            $table->index('due_period_id');
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->char('currency', 3)->default('BDT');
            $table->string('method', 32);
            $table->timestamp('received_at');
            $table->foreignId('recorded_by')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('posted');
            $table->string('receipt_number', 40)->unique();
            $table->string('idempotency_key', 100)->unique();
            $table->text('notes')->nullable();
            $table->timestamp('reversed_at')->nullable();
            $table->foreignId('reversed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('reversal_reason', 500)->nullable();
            $table->timestamps();

            $table->index(['user_id', 'received_at']);
            $table->index('status');
        });

        Schema::create('payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_due_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->boolean('is_reversed')->default(false);
            $table->timestamps();

            $table->index(['payment_id', 'is_reversed']);
            $table->index(['member_due_id', 'is_reversed']);
        });

        Schema::create('financial_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 64);
            $table->string('entity_type', 100);
            $table->unsignedBigInteger('entity_id');
            $table->json('before')->nullable();
            $table->json('after')->nullable();
            $table->json('meta')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['entity_type', 'entity_id']);
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('financial_audit_logs');
        Schema::dropIfExists('payment_allocations');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('member_dues');
        Schema::dropIfExists('due_periods');
        Schema::dropIfExists('member_contribution_assignments');
        Schema::dropIfExists('contribution_plans');
    }
};
