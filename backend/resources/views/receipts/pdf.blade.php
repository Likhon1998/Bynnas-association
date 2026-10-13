<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Receipt {{ $payment->receipt_number }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #111; }
        h1 { font-size: 18px; margin: 0 0 4px; }
        .muted { color: #555; }
        .row { margin: 10px 0; }
        .amount { font-size: 20px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { border: 1px solid #ccc; padding: 6px; text-align: left; }
        th { background: #eee; }
        td.num { text-align: right; }
        .reversed { color: #9f1239; font-weight: bold; margin: 8px 0; }
    </style>
</head>
<body>
    <h1>{{ $association }}</h1>
    <div class="muted">Official payment receipt · Generated {{ $generated_at }}</div>
    <div class="row"><strong>Receipt:</strong> {{ $payment->receipt_number }}</div>
    @if ($payment->status?->value === 'reversed')
        <div class="reversed">REVERSED — NOT A VALID ACTIVE PAYMENT</div>
    @endif
    <div class="row"><strong>Member:</strong> {{ $payment->member?->name }} ({{ $payment->member?->member_id }})</div>
    <div class="row"><strong>Date:</strong> {{ optional($payment->received_at)->format('Y-m-d H:i') }}</div>
    <div class="row amount">Amount: ৳ {{ \App\Support\Money::normalize((string) $payment->amount) }} {{ $payment->currency }}</div>
    <div class="row"><strong>Method:</strong> {{ str_replace('_', ' ', ucfirst($payment->method?->value)) }}</div>
    <div class="row"><strong>Issuer:</strong> {{ $payment->recordedBy?->name ?: 'System-generated' }}</div>

    <table>
        <thead>
            <tr>
                <th>Period</th>
                <th>Plan</th>
                <th class="num">Amount</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($payment->allocations as $allocation)
                <tr>
                    <td>{{ $allocation->memberDue?->period?->label ?: '—' }}</td>
                    <td>{{ $allocation->memberDue?->plan?->name ?: '—' }}</td>
                    <td class="num">{{ \App\Support\Money::normalize((string) $allocation->amount) }}</td>
                </tr>
            @empty
                <tr><td colspan="3">No period allocations.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
