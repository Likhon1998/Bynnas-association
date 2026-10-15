<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('member_profiles', function (Blueprint $table) {
            $table->string('occupation', 120)->nullable()->after('address');
            $table->string('photo_path', 500)->nullable()->after('occupation');
        });

        Schema::create('sms_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->string('body', 1000);
            $table->string('audience_type', 40)->default('all_active_members');
            $table->unsignedInteger('recipient_count')->default(0);
            $table->string('status', 32)->default('queued');
            $table->timestamps();
        });

        Schema::create('sms_deliveries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sms_message_id')->constrained('sms_messages')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('phone', 32);
            $table->string('status', 32)->default('pending');
            $table->string('provider_message_id', 120)->nullable();
            $table->text('error_message')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->index(['sms_message_id', 'status']);
        });

        Schema::create('financial_change_requests', function (Blueprint $table) {
            $table->id();
            $table->string('type', 40);
            $table->foreignId('payment_id')->nullable()->constrained('payments')->nullOnDelete();
            $table->foreignId('requested_by')->constrained('users')->cascadeOnDelete();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 32)->default('pending');
            $table->text('reason');
            $table->text('review_note')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'type']);
        });

        Schema::create('database_backups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('disk', 40)->default('local');
            $table->string('path', 500);
            $table->unsignedBigInteger('size_bytes')->default(0);
            $table->string('status', 32)->default('completed');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('database_backups');
        Schema::dropIfExists('financial_change_requests');
        Schema::dropIfExists('sms_deliveries');
        Schema::dropIfExists('sms_messages');

        Schema::table('member_profiles', function (Blueprint $table) {
            $table->dropColumn(['occupation', 'photo_path']);
        });
    }
};
