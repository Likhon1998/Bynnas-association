<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Month-wise report</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #111; margin: 24px; }
        h1 { font-size: 18px; margin: 0 0 8px; }
        .meta { color: #555; margin-bottom: 16px; }
        .summary { margin-bottom: 16px; }
        .summary span { display: inline-block; margin-right: 18px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
        th { background: #f3f4f6; }
        td.num, th.num { text-align: right; }
        @media print {
            .no-print { display: none !important; }
            body { margin: 12px; }
        }
    </style>
</head>
<body onload="window.print()">
    <div class="no-print" style="margin-bottom: 12px;">
        <button onclick="window.print()">Print</button>
    </div>
    <h1>Month-wise contribution report</h1>
    <div class="meta">
        Generated {{ now()->toDateTimeString() }}
        @if ($from || $to)
            · Filter: {{ $from ?: '…' }} to {{ $to ?: '…' }}
        @endif
    </div>
    <div class="summary">
        <span><strong>Expected:</strong> {{ $summary['expected_dues'] }}</span>
        <span><strong>Collected:</strong> {{ $summary['actual_collections'] }}</span>
        <span><strong>Allocated:</strong> {{ $summary['allocated_to_dues'] }}</span>
        <span><strong>Outstanding:</strong> {{ $summary['outstanding'] }}</span>
    </div>
    <table>
        <thead>
            <tr>
                <th>Period</th>
                <th class="num">Expected</th>
                <th class="num">Collected</th>
                <th class="num">Allocated</th>
                <th class="num">Outstanding</th>
                <th>Status (P/Part/Paid)</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($rows as $row)
                <tr>
                    <td>{{ $row['label'] }}</td>
                    <td class="num">{{ $row['expected_dues'] }}</td>
                    <td class="num">{{ $row['actual_collections'] }}</td>
                    <td class="num">{{ $row['allocated_to_dues'] }}</td>
                    <td class="num">{{ $row['outstanding'] }}</td>
                    <td>{{ $row['payment_status']['pending'] }}/{{ $row['payment_status']['partial'] }}/{{ $row['payment_status']['paid'] }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
