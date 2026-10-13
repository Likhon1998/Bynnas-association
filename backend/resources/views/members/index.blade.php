<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between gap-4">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Members') }}
            </h2>
            @if (auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                <a href="{{ route('members.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">
                    {{ __('Add member') }}
                </a>
            @endif
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">
                    {{ session('status') }}
                </div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" action="{{ route('members.index') }}" class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div class="md:col-span-2">
                        <x-input-label for="search" :value="__('Search')" />
                        <x-text-input id="search" name="search" class="block mt-1 w-full" :value="$search" placeholder="Name, email, member ID, phone" />
                    </div>
                    <div>
                        <x-input-label for="status" :value="__('Status')" />
                        <select id="status" name="status" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">
                            <option value="">{{ __('All') }}</option>
                            <option value="active" @selected($status === 'active')>{{ __('Active') }}</option>
                            <option value="inactive" @selected($status === 'inactive')>{{ __('Inactive') }}</option>
                        </select>
                    </div>
                    <div class="flex items-end">
                        <x-primary-button class="w-full justify-center">{{ __('Filter') }}</x-primary-button>
                    </div>
                </form>
            </div>

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Member ID') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Name') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Email') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Phone') }}</th>
                                <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Status') }}</th>
                                <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Actions') }}</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100">
                            @forelse ($members as $member)
                                <tr>
                                    <td class="px-4 py-3 font-medium text-gray-900">{{ $member->member_id }}</td>
                                    <td class="px-4 py-3">{{ $member->name }}</td>
                                    <td class="px-4 py-3">{{ $member->email }}</td>
                                    <td class="px-4 py-3">{{ $member->memberProfile?->phone ?: '—' }}</td>
                                    <td class="px-4 py-3">
                                        @if ($member->is_active)
                                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800">{{ __('Active') }}</span>
                                        @else
                                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800">{{ __('Inactive') }}</span>
                                        @endif
                                    </td>
                                    <td class="px-4 py-3 text-right space-x-2">
                                        <a href="{{ route('members.show', $member) }}" class="text-indigo-600 hover:underline">{{ __('View') }}</a>
                                        @if (auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                                            <a href="{{ route('members.edit', $member) }}" class="text-gray-700 hover:underline">{{ __('Edit') }}</a>
                                        @endif
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
                <div class="px-4 py-3 border-t border-gray-100">
                    {{ $members->links() }}
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
