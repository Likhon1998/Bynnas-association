<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
                <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ $headline }}</h2>
                <p class="text-sm text-gray-500 mt-1">
                    {{ __('Role') }}: {{ str_replace('_', ' ', ucfirst($variant)) }} · {{ __('Totals from server') }}
                </p>
            </div>
            <div class="flex flex-wrap gap-2 print:hidden">
                @if (!empty($canManagePayments))
                    <a href="{{ route('payments.create') }}" class="inline-flex items-center px-3 py-2 bg-emerald-600 border border-transparent rounded-md text-xs font-semibold uppercase tracking-widest text-white hover:bg-emerald-500">
                        {{ __('Record payment') }}
                    </a>
                @endif
                <a href="{{ route('payments.index') }}" class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">
                    {{ __('Payments') }}
                </a>
                <a href="{{ route('reports.member-wise') }}" class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">
                    {{ __('Member report') }}
                </a>
                <a href="{{ route('reports.month-wise') }}" class="inline-flex items-center px-3 py-2 bg-indigo-600 border border-transparent rounded-md text-xs font-semibold uppercase tracking-widest text-white hover:bg-indigo-500">
                    {{ __('Month report') }}
                </a>
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-6">
            <div class="bg-white shadow-sm sm:rounded-lg p-6 print:hidden">
                <form method="GET" action="{{ route('dashboard') }}" class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                        <x-input-label for="from" :value="__('From')" />
                        <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$from" />
                    </div>
                    <div>
                        <x-input-label for="to" :value="__('To')" />
                        <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$to" />
                    </div>
                    <div class="md:col-span-2 flex items-end gap-2">
                        <x-primary-button>{{ __('Apply filters') }}</x-primary-button>
                        <a href="{{ route('dashboard') }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">
                            {{ __('Reset') }}
                        </a>
                    </div>
                </form>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Active members') }}</p>
                    <p class="mt-2 text-3xl font-semibold text-gray-900">{{ $summary['active_members'] }}</p>
                    <p class="text-sm text-gray-500 mt-1">{{ __('of') }} {{ $summary['total_members'] }} {{ __('total') }}</p>
                </div>
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Expected dues') }}</p>
                    <p class="mt-2 text-3xl font-semibold text-gray-900">৳ {{ $summary['expected_dues'] }}</p>
                    <p class="text-sm text-gray-500 mt-1">{{ $summary['currency'] }}</p>
                </div>
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Actual collections') }}</p>
                    <p class="mt-2 text-3xl font-semibold text-emerald-700">৳ {{ $summary['actual_collections'] }}</p>
                    <p class="text-sm text-gray-500 mt-1">{{ $summary['recent_payments_count'] }} {{ __('posted payments') }}</p>
                </div>
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Outstanding') }}</p>
                    <p class="mt-2 text-3xl font-semibold text-amber-700">৳ {{ $summary['outstanding'] }}</p>
                    <p class="text-sm text-gray-500 mt-1">{{ __('Allocated') }}: {{ $summary['allocated_to_dues'] }}</p>
                </div>
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Collection rate') }}</p>
                    <p class="mt-2 text-3xl font-semibold text-indigo-700">{{ $summary['collection_rate'] ?? '0.00' }}%</p>
                    <p class="text-sm text-gray-500 mt-1">{{ __('Collected ÷ expected') }}</p>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <h3 class="text-sm font-semibold text-gray-800 uppercase tracking-wide">{{ __('Current month') }}</h3>
                    <dl class="mt-3 space-y-2 text-sm">
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Expected') }}</dt><dd class="font-semibold">৳ {{ $summary['current_month']['expected_dues'] ?? '0.00' }}</dd></div>
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Collected') }}</dt><dd class="font-semibold text-emerald-700">৳ {{ $summary['current_month']['actual_collections'] ?? '0.00' }}</dd></div>
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Outstanding') }}</dt><dd class="font-semibold text-amber-700">৳ {{ $summary['current_month']['outstanding'] ?? '0.00' }}</dd></div>
                    </dl>
                </div>
                <div class="bg-white shadow-sm sm:rounded-lg p-5">
                    <h3 class="text-sm font-semibold text-gray-800 uppercase tracking-wide">{{ __('Previous month') }}</h3>
                    <dl class="mt-3 space-y-2 text-sm">
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Expected') }}</dt><dd class="font-semibold">৳ {{ $summary['previous_month']['expected_dues'] ?? '0.00' }}</dd></div>
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Collected') }}</dt><dd class="font-semibold text-emerald-700">৳ {{ $summary['previous_month']['actual_collections'] ?? '0.00' }}</dd></div>
                        <div class="flex justify-between"><dt class="text-gray-500">{{ __('Outstanding') }}</dt><dd class="font-semibold text-amber-700">৳ {{ $summary['previous_month']['outstanding'] ?? '0.00' }}</dd></div>
                    </dl>
                </div>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <h3 class="text-sm font-semibold text-gray-800 uppercase tracking-wide">{{ __('Payment status (dues)') }}</h3>
                <div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div class="rounded-lg bg-gray-50 p-4">
                        <p class="text-gray-500">{{ __('Pending') }}</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ $summary['payment_status']['pending'] }}</p>
                    </div>
                    <div class="rounded-lg bg-amber-50 p-4">
                        <p class="text-amber-700">{{ __('Partial') }}</p>
                        <p class="text-2xl font-semibold text-amber-900">{{ $summary['payment_status']['partial'] }}</p>
                    </div>
                    <div class="rounded-lg bg-emerald-50 p-4">
                        <p class="text-emerald-700">{{ __('Paid') }}</p>
                        <p class="text-2xl font-semibold text-emerald-900">{{ $summary['payment_status']['paid'] }}</p>
                    </div>
                    <div class="rounded-lg bg-slate-50 p-4">
                        <p class="text-slate-500">{{ __('Voided') }}</p>
                        <p class="text-2xl font-semibold text-slate-800">{{ $summary['payment_status']['voided'] }}</p>
                    </div>
                </div>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="px-4 py-3 border-b flex items-center justify-between">
                    <h3 class="text-sm font-semibold text-gray-800 uppercase tracking-wide">{{ __('Recent payments') }}</h3>
                    <a href="{{ route('payments.index') }}" class="text-xs text-indigo-600 hover:underline">{{ __('View all') }}</a>
                </div>
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-4 py-3 text-left">{{ __('Receipt') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('Member') }}</th>
                            <th class="px-4 py-3 text-right">{{ __('Amount') }}</th>
                            <th class="px-4 py-3 text-left">{{ __('Date') }}</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @forelse (($summary['recent_payments'] ?? []) as $payment)
                            <tr>
                                <td class="px-4 py-3 font-mono text-xs">
                                    <a href="{{ route('payments.show', $payment['id']) }}" class="text-indigo-600 hover:underline">{{ $payment['receipt_number'] }}</a>
                                </td>
                                <td class="px-4 py-3">{{ $payment['member_name'] }} ({{ $payment['member_id'] }})</td>
                                <td class="px-4 py-3 text-right">৳ {{ $payment['amount'] }}</td>
                                <td class="px-4 py-3">{{ $payment['received_at'] }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" class="px-4 py-6 text-center text-gray-500">{{ __('No recent payments for this filter.') }}</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if ($variant === 'accountant')
                <div class="bg-indigo-50 border border-indigo-100 rounded-lg p-4 text-sm text-indigo-900">
                    {{ __('Accountant view focuses on collections, allocations, and outstanding balances. Use reports for member-wise and month-wise breakdowns.') }}
                </div>
            @elseif ($variant === 'super_admin')
                <div class="bg-slate-50 border border-slate-200 rounded-lg p-4 text-sm text-slate-800">
                    {{ __('Super Admin overview includes membership health plus full financial totals. Manage members from the Members menu.') }}
                </div>
            @else
                <div class="bg-slate-50 border border-slate-200 rounded-lg p-4 text-sm text-slate-800">
                    {{ __('Admin overview shows association membership and dues performance for the selected period.') }}
                </div>
            @endif
        </div>
    </div>
</x-app-layout>
