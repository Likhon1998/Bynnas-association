<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
                <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Payment') }} {{ $payment->receipt_number }}</h2>
                <p class="text-sm text-gray-500 mt-1">{{ $payment->member?->name }} · {{ $payment->member?->member_id }}</p>
            </div>
            <div class="flex flex-wrap gap-2">
                <a href="{{ route('receipts.show', $payment) }}" class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">{{ __('Receipt') }}</a>
                <a href="{{ route('receipts.pdf', $payment) }}" class="inline-flex items-center px-3 py-2 bg-indigo-600 border border-transparent rounded-md text-xs font-semibold uppercase tracking-widest text-white hover:bg-indigo-500">{{ __('PDF') }}</a>
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">{{ session('status') }}</div>
            @endif
            @if ($errors->any())
                <div class="bg-rose-50 border border-rose-200 text-rose-800 rounded-lg px-4 py-3">{{ $errors->first() }}</div>
            @endif

            @if ($payment->status?->value === 'reversed')
                <div class="bg-rose-50 border border-rose-200 text-rose-900 rounded-lg px-4 py-3">
                    <strong>{{ __('REVERSED') }}</strong>
                    — {{ $payment->reversal_reason }}
                    @if ($payment->reversed_at)
                        <span class="text-sm">({{ $payment->reversed_at->format('Y-m-d H:i') }})</span>
                    @endif
                </div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6 grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                    <div class="text-gray-500">{{ __('Amount') }}</div>
                    <div class="text-2xl font-semibold text-gray-900">৳ {{ \App\Support\Money::normalize((string) $payment->amount) }}</div>
                </div>
                <div>
                    <div class="text-gray-500">{{ __('Status') }}</div>
                    <div class="font-semibold text-gray-900">{{ ucfirst($payment->status?->value) }}</div>
                </div>
                <div>
                    <div class="text-gray-500">{{ __('Received at') }}</div>
                    <div class="font-semibold text-gray-900">{{ optional($payment->received_at)->format('Y-m-d H:i') }}</div>
                </div>
                <div>
                    <div class="text-gray-500">{{ __('Method') }}</div>
                    <div class="font-semibold text-gray-900">{{ str_replace('_', ' ', ucfirst($payment->method?->value)) }}</div>
                </div>
                <div>
                    <div class="text-gray-500">{{ __('Recorded by') }}</div>
                    <div class="font-semibold text-gray-900">{{ $payment->recordedBy?->name ?: __('System') }}</div>
                </div>
                <div>
                    <div class="text-gray-500">{{ __('Notes') }}</div>
                    <div class="font-semibold text-gray-900">{{ $payment->notes ?: '—' }}</div>
                </div>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="px-4 py-3 border-b font-semibold text-gray-800">{{ __('Allocations') }}</div>
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-4 py-3 text-left">{{ __('Period') }}</th>
                            <th class="px-4 py-3 text-right">{{ __('Amount') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('State') }}</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @forelse ($payment->allocations as $allocation)
                            <tr>
                                <td class="px-4 py-3">{{ $allocation->memberDue?->period?->label ?: '—' }}</td>
                                <td class="px-4 py-3 text-right">৳ {{ \App\Support\Money::normalize((string) $allocation->amount) }}</td>
                                <td class="px-4 py-3">{{ $allocation->is_reversed ? __('Reversed') : __('Active') }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="px-4 py-6 text-center text-gray-500">{{ __('No allocations recorded.') }}</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if ($payment->status?->value === 'posted')
                <div class="bg-white shadow-sm sm:rounded-lg p-6">
                    <h3 class="font-semibold text-gray-800 mb-3">{{ __('Reverse payment') }}</h3>
                    <p class="text-sm text-gray-500 mb-4">{{ __('Reversal preserves history and restores due balances. It never deletes the payment.') }}</p>
                    <form method="POST" action="{{ route('payments.reverse', $payment) }}" class="space-y-3" onsubmit="return confirm('Reverse this payment?');">
                        @csrf
                        <div>
                            <x-input-label for="reason" :value="__('Reason')" />
                            <textarea id="reason" name="reason" rows="3" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full" required>{{ old('reason') }}</textarea>
                            <x-input-error :messages="$errors->get('reason')" class="mt-2" />
                        </div>
                        <x-danger-button type="submit">{{ __('Reverse payment') }}</x-danger-button>
                    </form>
                </div>
            @endif

            <a href="{{ route('payments.index') }}" class="text-sm text-indigo-600 hover:underline">{{ __('Back to payments') }}</a>
        </div>
    </div>
</x-app-layout>
