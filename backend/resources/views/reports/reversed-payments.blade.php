<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Reversed payments & adjustments') }}</h2>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-4">
            <div class="bg-amber-50 border border-amber-200 text-amber-900 rounded-lg px-4 py-3 text-sm">
                {{ __('Reversed payments remain in the ledger. They are never deleted.') }}
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                        <x-input-label for="search" :value="__('Search')" />
                        <x-text-input id="search" name="search" class="block mt-1 w-full" :value="$search" />
                    </div>
                    <div>
                        <x-input-label for="from" :value="__('From')" />
                        <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$from" />
                    </div>
                    <div>
                        <x-input-label for="to" :value="__('To')" />
                        <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$to" />
                    </div>
                    <div class="flex items-end">
                        <x-primary-button>{{ __('Filter') }}</x-primary-button>
                    </div>
                </form>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-4 py-3 text-left">{{ __('Receipt') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('Member') }}</th>
                            <th class="px-4 py-3 text-right">{{ __('Amount') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('Reversed at') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('Reason') }}</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @forelse ($payments as $payment)
                            <tr>
                                <td class="px-4 py-3 font-mono text-xs">
                                    <a class="text-indigo-600 hover:underline" href="{{ route('payments.show', $payment) }}">{{ $payment->receipt_number }}</a>
                                </td>
                                <td class="px-4 py-3">{{ $payment->member?->name }}</td>
                                <td class="px-4 py-3 text-right">৳ {{ \App\Support\Money::normalize((string) $payment->amount) }}</td>
                                <td class="px-4 py-3">{{ optional($payment->reversed_at)->format('Y-m-d H:i') }}</td>
                                <td class="px-4 py-3">{{ $payment->reversal_reason }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="px-4 py-8 text-center text-gray-500">{{ __('No reversed payments.') }}</td></tr>
                        @endforelse
                    </tbody>
                </table>
                <div class="px-4 py-3 border-t">{{ $payments->links() }}</div>
            </div>
        </div>
    </div>
</x-app-layout>
