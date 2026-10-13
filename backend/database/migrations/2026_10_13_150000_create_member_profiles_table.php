<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('phone', 32)->nullable();
            $table->string('address', 500)->nullable();
            $table->text('notes')->nullable();
            $table->date('joined_on')->nullable();
            $table->timestamps();

            $table->unique('user_id');
            $table->index('phone');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_profiles');
    }
};
