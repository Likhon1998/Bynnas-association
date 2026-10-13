@php($isReversed = $payment->status?->value === 'reversed')
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('Receipt') }} {{ $payment->receipt_number }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        @media print {
            .no-print { display: none !important; }
            body { background: white; }
        }
    </style>
</head>
<body class="bg-gray-100 text-gray-900">
    <div class="no-print max-w-3xl mx-auto px-4 py-4 flex gap-2">
        <a href="{{ route('payments.show', $payment) }}" class="px-3 py-2 bg-white border rounded-md text-sm">{{ __('Back') }}</a>
        <button onclick="window.print()" class="px-3 py-2 bg-white border rounded-md text-sm">{{ __('Print') }}</button>
        <a href="{{ route('receipts.pdf', $payment) }}" class="px-3 py-2 bg-indigo-600 text-white rounded-md text-sm">{{ __('Download PDF') }}</a>
    </div>

    <div class="max-w-3xl mx-auto my-4 bg-white shadow-sm sm:rounded-lg p-8">
        <div class="flex justify-between items-start gap-4 border-b pb-4">
            <div>
                <h1 class="text-2xl font-bold">{{ $association }}</h1>
                <p class="text-sm text-gray-500">{{ __('Official payment receipt') }}</p>
            </div>
            <div class="text-right">
                <div class="font-mono text-sm">{{ $payment->receipt_number }}</div>
                @if ($isReversed)
                    <div class="mt-2 inline-flex px-2 py-1 rounded bg-rose-100 text-rose-800 text-xs font-bold">{{ __('REVERSED — NOT VALID') }}</div>
                @endif
            </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6 text-sm">
            <div>
                <div class="text-gray-500">{{ __('Member') }}</div>
                <div class="font-semibold">{{ $payment->member?->name }}</div>
                <div>{{ $payment->member?->member_id }}</div>
            </div>
            <div>
                <div class="text-gray-500">{{ __('Payment date') }}</div>
                <div class="font-semibold">{{ optional($payment->received_at)->format('Y-m-d H:i') }}</div>
            </div>
            <div>
                <div class="text-gray-500">{{ __('Amount') }}</div>
                <div class="text-2xl font-bold">৳ {{ \App\Support\Money::normalize((string) $payment->amount) }} {{ $payment->currency }}</div>
            </div>
            <div>
                <div class="text-gray-500">{{ __('Method') }}</div>
                <div class="font-semibold">{{ str_replace('_', ' ', ucfirst($payment->method?->value)) }}</div>
            </div>
        </div>

        <h2 class="mt-8 mb-3 font-semibold">{{ __('Contribution allocations') }}</h2>
        <table class="w-full text-sm border-collapse">
            <thead>
                <tr class="bg-gray-50">
                    <th class="border px-3 py-2 text-left">{{ __('Period') }}</th>
                    <th class="border px-3 py-2 text-left">{{ __('Plan') }}</th>
                    <th class="border px-3 py-2 text-right">{{ __('Amount') }}</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($payment->allocations as $allocation)
                    <tr>
                        <td class="border px-3 py-2">{{ $allocation->memberDue?->period?->label ?: '—' }}</td>
                        <td class="border px-3 py-2">{{ $allocation->memberDue?->plan?->name ?: '—' }}</td>
                        <td class="border px-3 py-2 text-right">৳ {{ \App\Support\Money::normalize((string) $allocation->amount) }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="3" class="border px-3 py-4 text-center text-gray-500">{{ __('No period allocations.') }}</td>
                    </tr>
                @endforelse
            </tbody>
        </table>

        <div class="mt-8 text-sm text-gray-600">
            {{ __('Authorized issuer') }}:
            <strong>{{ $payment->recordedBy?->name ?: __('System-generated') }}</strong>
        </div>
        @if ($isReversed)
            <div class="mt-4 p-3 border border-rose-300 bg-rose-50 text-rose-900 text-sm">
                {{ __('This receipt is reversed and must not be treated as a valid active payment confirmation.') }}
                @if ($payment->reversal_reason)
                    <div class="mt-1">{{ __('Reason') }}: {{ $payment->reversal_reason }}</div>
                @endif
            </div>
        @endif
    </div>
</body>
</html>
