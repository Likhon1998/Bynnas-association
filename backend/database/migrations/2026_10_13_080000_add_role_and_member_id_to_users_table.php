<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 32)->default('member')->after('email');
            $table->string('member_id', 32)->nullable()->unique()->after('role');
            $table->boolean('is_active')->default(true)->after('member_id');
            $table->timestamp('deactivated_at')->nullable()->after('is_active');

            $table->index('role');
            $table->index('is_active');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role']);
            $table->dropIndex(['is_active']);
            $table->dropColumn(['role', 'member_id', 'is_active', 'deactivated_at']);
        });
    }
};
