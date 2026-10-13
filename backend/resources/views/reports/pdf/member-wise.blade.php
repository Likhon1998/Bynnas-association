<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #111; }
        h1 { font-size: 16px; margin: 0 0 6px; }
        .meta { color: #555; margin-bottom: 12px; }
        .summary { margin-bottom: 12px; }
        .summary span { display: inline-block; margin-right: 14px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 5px 6px; text-align: left; }
        th { background: #eee; }
        td.num, th.num { text-align: right; }
    </style>
</head>
<body>
    <h1>{{ $title }}</h1>
    <div class="meta">Generated {{ $generated_at }} · Currency {{ $summary['currency'] }}</div>
    <div class="summary">
        <span><strong>Expected:</strong> {{ $summary['expected_dues'] }}</span>
        <span><strong>Collected:</strong> {{ $summary['actual_collections'] }}</span>
        <span><strong>Allocated:</strong> {{ $summary['allocated_to_dues'] }}</span>
        <span><strong>Outstanding:</strong> {{ $summary['outstanding'] }}</span>
    </div>
    <table>
        <thead>
            <tr>
                <th>Member</th>
                <th class="num">Expected</th>
                <th class="num">Collected</th>
                <th class="num">Allocated</th>
                <th class="num">Outstanding</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($rows as $row)
                <tr>
                    <td>{{ $row['name'] }} ({{ $row['member_id'] }})</td>
                    <td class="num">{{ $row['expected_dues'] }}</td>
                    <td class="num">{{ $row['actual_collections'] }}</td>
                    <td class="num">{{ $row['allocated_to_dues'] }}</td>
                    <td class="num">{{ $row['outstanding'] }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
