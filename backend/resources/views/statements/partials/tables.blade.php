<div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
    <div class="px-4 py-3 border-b font-semibold">{{ __('Monthly contribution status') }}</div>
    <div class="overflow-x-auto">
        <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-4 py-3 text-left">{{ __('Period') }}</th>
                    <th class="px-4 py-3 text-right">{{ __('Due') }}</th>
                    <th class="px-4 py-3 text-right">{{ __('Paid') }}</th>
                    <th class="px-4 py-3 text-right">{{ __('Outstanding') }}</th>
                    <th class="px-4 py-3 text-left">{{ __('Status') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse ($statement['dues'] as $due)
                    <tr>
                        <td class="px-4 py-3">{{ $due['period_label'] }}</td>
                        <td class="px-4 py-3 text-right">{{ $due['amount_due'] }}</td>
                        <td class="px-4 py-3 text-right">{{ $due['amount_allocated'] }}</td>
                        <td class="px-4 py-3 text-right">{{ $due['outstanding'] }}</td>
                        <td class="px-4 py-3">{{ ucfirst($due['status']) }}</td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="px-4 py-6 text-center text-gray-500">{{ __('No dues in this period.') }}</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
    <div class="px-4 py-3 border-b font-semibold">{{ __('Payment history') }}</div>
    <div class="overflow-x-auto">
        <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-4 py-3 text-left">{{ __('Receipt') }}</th>
                    <th class="px-4 py-3 text-left">{{ __('Date') }}</th>
                    <th class="px-4 py-3 text-right">{{ __('Amount') }}</th>
                    <th class="px-4 py-3 text-left">{{ __('Status') }}</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse ($statement['payments'] as $payment)
                    <tr class="{{ $payment['status'] === 'reversed' ? 'bg-rose-50/50' : '' }}">
                        <td class="px-4 py-3 font-mono text-xs">
                            <a href="{{ route('receipts.show', $payment['id']) }}" class="text-indigo-600 hover:underline">{{ $payment['receipt_number'] }}</a>
                        </td>
                        <td class="px-4 py-3">{{ $payment['received_at'] }}</td>
                        <td class="px-4 py-3 text-right">{{ $payment['amount'] }}</td>
                        <td class="px-4 py-3">{{ ucfirst($payment['status']) }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="px-4 py-6 text-center text-gray-500">{{ __('No payments in this period.') }}</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
