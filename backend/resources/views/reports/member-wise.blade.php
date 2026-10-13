<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Member-wise report') }}</h2>
            <div class="flex flex-wrap gap-2 print:hidden">
                <a href="{{ route('reports.member-wise', array_filter(['from' => $from, 'to' => $to, 'search' => $search, 'print' => 1])) }}"
                   target="_blank"
                   class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">
                    {{ __('Print') }}
                </a>
                <a href="{{ route('reports.member-wise.csv', array_filter(['from' => $from, 'to' => $to, 'search' => $search])) }}"
                   class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">
                    {{ __('CSV') }}
                </a>
                <a href="{{ route('reports.member-wise.pdf', array_filter(['from' => $from, 'to' => $to, 'search' => $search])) }}"
                   class="inline-flex items-center px-3 py-2 bg-indigo-600 border border-transparent rounded-md text-xs font-semibold uppercase tracking-widest text-white hover:bg-indigo-500">
                    {{ __('Export PDF') }}
                </a>
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-4">
            <div class="bg-white shadow-sm sm:rounded-lg p-6 print:hidden">
                <form method="GET" action="{{ route('reports.member-wise') }}" class="grid grid-cols-1 md:grid-cols-5 gap-4">
                    <div>
                        <x-input-label for="from" :value="__('From')" />
                        <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$from" />
                    </div>
                    <div>
                        <x-input-label for="to" :value="__('To')" />
                        <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$to" />
                    </div>
                    <div class="md:col-span-2">
                        <x-input-label for="search" :value="__('Search')" />
                        <x-text-input id="search" name="search" class="block mt-1 w-full" :value="$search" placeholder="Name, email, member ID" />
                    </div>
                    <div class="flex items-end">
                        <x-primary-button class="w-full justify-center">{{ __('Filter') }}</x-primary-button>
                    </div>
                </form>
            </div>

            @include('reports.partials.summary-cards', ['summary' => $summary])

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Member') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Expected') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Collected') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Allocated') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Outstanding') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Due status') }}</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100">
                            @forelse ($rows as $row)
                                <tr>
                                    <td class="px-4 py-3">
                                        <div class="font-medium text-gray-900">{{ $row['name'] }}</div>
                                        <div class="text-xs text-gray-500">{{ $row['member_id'] }} · {{ $row['is_active'] ? __('Active') : __('Inactive') }}</div>
                                    </td>
                                    <td class="px-4 py-3 text-right">{{ $row['expected_dues'] }}</td>
                                    <td class="px-4 py-3 text-right">{{ $row['actual_collections'] }}</td>
                                    <td class="px-4 py-3 text-right">{{ $row['allocated_to_dues'] }}</td>
                                    <td class="px-4 py-3 text-right font-medium">{{ $row['outstanding'] }}</td>
                                    <td class="px-4 py-3 text-xs text-gray-600">
                                        P {{ $row['payment_status']['pending'] }} /
                                        Part {{ $row['payment_status']['partial'] }} /
                                        Paid {{ $row['payment_status']['paid'] }}
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="6" class="px-4 py-8 text-center text-gray-500">{{ __('No members found.') }}</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="px-4 py-3 border-t border-gray-100 print:hidden">
                    {{ $rows->links() }}
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
