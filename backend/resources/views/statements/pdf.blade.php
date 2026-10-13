<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Member statement</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #111; }
        h1 { font-size: 16px; margin: 0 0 4px; }
        .muted { color: #555; margin-bottom: 10px; }
        .cards span { display: inline-block; margin-right: 12px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 14px; }
        th, td { border: 1px solid #ccc; padding: 5px; text-align: left; }
        th { background: #eee; }
        td.num { text-align: right; }
    </style>
</head>
<body>
    <h1>{{ $association }} — Member statement</h1>
    <div class="muted">
        {{ $statement['member']['name'] }} ({{ $statement['member']['member_id'] }})
        · Generated {{ $generated_at }}
    </div>
    <div class="cards">
        <span><strong>Expected:</strong> {{ $statement['summary']['expected_dues'] }}</span>
        <span><strong>Paid:</strong> {{ $statement['summary']['total_paid'] }}</span>
        <span><strong>Outstanding:</strong> {{ $statement['summary']['outstanding'] }}</span>
    </div>

    <h2>Dues</h2>
    <table>
        <thead>
            <tr>
                <th>Period</th>
                <th class="num">Due</th>
                <th class="num">Allocated</th>
                <th class="num">Outstanding</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($statement['dues'] as $due)
                <tr>
                    <td>{{ $due['period_label'] }}</td>
                    <td class="num">{{ $due['amount_due'] }}</td>
                    <td class="num">{{ $due['amount_allocated'] }}</td>
                    <td class="num">{{ $due['outstanding'] }}</td>
                    <td>{{ $due['status'] }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Payments</h2>
    <table>
        <thead>
            <tr>
                <th>Receipt</th>
                <th>Date</th>
                <th class="num">Amount</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($statement['payments'] as $payment)
                <tr>
                    <td>{{ $payment['receipt_number'] }}</td>
                    <td>{{ $payment['received_at'] }}</td>
                    <td class="num">{{ $payment['amount'] }}</td>
                    <td>{{ $payment['status'] }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
