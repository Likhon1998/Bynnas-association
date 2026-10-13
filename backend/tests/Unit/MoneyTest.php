<?php

namespace Tests\Unit;

use App\Support\Money;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class MoneyTest extends TestCase
{
    public function test_normalizes_and_adds_without_float_drift(): void
    {
        $this->assertSame('0.30', Money::add('0.10', '0.20'));
        $this->assertSame('100.00', Money::sub('500.00', '400.00'));
        $this->assertSame(0, Money::compare('10.00', '10.00'));
        $this->assertTrue(Money::isPositive('0.01'));
        $this->assertTrue(Money::isZero('0.00'));
    }

    public function test_rejects_floats(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Money::normalize(0.1);
    }
}
