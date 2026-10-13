<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Payments') }}</h2>
            <a href="{{ route('payments.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">
                {{ __('Record payment') }}
            </a>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">{{ session('status') }}</div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" action="{{ route('payments.index') }}" class="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-6 gap-4">
                    <div class="xl:col-span-2">
                        <x-input-label for="search" :value="__('Member / receipt search')" />
                        <x-text-input id="search" name="search" class="block mt-1 w-full" :value="$filters['search']" placeholder="Name, member ID, receipt" />
                    </div>
                    <div>
                        <x-input-label for="receipt_number" :value="__('Receipt #')" />
                        <x-text-input id="receipt_number" name="receipt_number" class="block mt-1 w-full" :value="$filters['receipt_number']" />
                    </div>
                    <div>
                        <x-input-label for="status" :value="__('Status')" />
                        <select id="status" name="status" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">
                            <option value="">{{ __('All') }}</option>
                            @foreach ($statuses as $status)
                                <option value="{{ $status->value }}" @selected(($filters['status'] ?? '') === $status->value)>{{ ucfirst($status->value) }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <x-input-label for="from" :value="__('From')" />
                        <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$filters['from']" />
                    </div>
                    <div>
                        <x-input-label for="to" :value="__('To')" />
                        <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$filters['to']" />
                    </div>
                    <div class="md:col-span-3 xl:col-span-6 flex gap-2">
                        <x-primary-button>{{ __('Filter') }}</x-primary-button>
                        <a href="{{ route('payments.index') }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">{{ __('Reset') }}</a>
                    </div>
                </form>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Receipt') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Member') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Amount') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Date') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Status') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Actions') }}</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100">
                            @forelse ($payments as $payment)
                                <tr class="{{ $payment->status?->value === 'reversed' ? 'bg-rose-50/40' : '' }}">
                                    <td class="px-4 py-3 font-mono text-xs">{{ $payment->receipt_number }}</td>
                                    <td class="px-4 py-3">
                                        <div class="font-medium text-gray-900">{{ $payment->member?->name }}</div>
                                        <div class="text-xs text-gray-500">{{ $payment->member?->member_id }}</div>
                                    </td>
                                    <td class="px-4 py-3 text-right font-semibold">৳ {{ \App\Support\Money::normalize((string) $payment->amount) }}</td>
                                    <td class="px-4 py-3">{{ optional($payment->received_at)->format('Y-m-d H:i') }}</td>
                                    <td class="px-4 py-3">
                                        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold {{ $payment->status?->value === 'reversed' ? 'bg-rose-100 text-rose-800' : 'bg-emerald-100 text-emerald-800' }}">
                                            {{ ucfirst($payment->status?->value) }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3 text-right space-x-2">
                                        <a href="{{ route('payments.show', $payment) }}" class="text-indigo-600 hover:underline">{{ __('View') }}</a>
                                        <a href="{{ route('receipts.show', $payment) }}" class="text-gray-600 hover:underline">{{ __('Receipt') }}</a>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="6" class="px-4 py-8 text-center text-gray-500">{{ __('No payments found.') }}</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="px-4 py-3 border-t">{{ $payments->links() }}</div>
            </div>
        </div>
    </div>
</x-app-layout>
