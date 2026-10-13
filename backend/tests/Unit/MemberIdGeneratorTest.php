<?php

namespace Tests\Unit;

use App\Models\User;
use App\Services\MemberIdGenerator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MemberIdGeneratorTest extends TestCase
{
    use RefreshDatabase;

    public function test_generates_first_member_id_for_year(): void
    {
        $generator = new MemberIdGenerator;

        $memberId = $generator->generate(2026);

        $this->assertSame('BYN-2026-0001', $memberId);
    }

    public function test_increments_sequence_for_existing_ids(): void
    {
        User::factory()->member('BYN-2026-0003')->create();

        $generator = new MemberIdGenerator;

        $this->assertSame('BYN-2026-0004', $generator->generate(2026));
    }
}
