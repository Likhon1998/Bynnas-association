<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between gap-4">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Notices') }}</h2>
            @if (auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                <a href="{{ route('notices.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">
                    {{ __('New notice') }}
                </a>
            @endif
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">{{ session('status') }}</div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" action="{{ route('notices.index') }}" class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                        <x-input-label for="status" :value="__('Status')" />
                        <select id="status" name="status" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">
                            <option value="">{{ __('All') }}</option>
                            <option value="draft" @selected($status === 'draft')>{{ __('Draft') }}</option>
                            <option value="published" @selected($status === 'published')>{{ __('Published') }}</option>
                            <option value="archived" @selected($status === 'archived')>{{ __('Archived') }}</option>
                        </select>
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
                            <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Title') }}</th>
                            <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Audience') }}</th>
                            <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Status') }}</th>
                            <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ __('Recipients') }}</th>
                            <th class="px-4 py-3 text-right font-semibold text-gray-600">{{ __('Actions') }}</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @forelse ($notices as $notice)
                            <tr>
                                <td class="px-4 py-3 font-medium text-gray-900">{{ $notice->title }}</td>
                                <td class="px-4 py-3">{{ str_replace('_', ' ', $notice->audience_type->value) }}</td>
                                <td class="px-4 py-3">{{ ucfirst($notice->status->value) }}</td>
                                <td class="px-4 py-3">{{ $notice->recipient_count }}</td>
                                <td class="px-4 py-3 text-right">
                                    <a href="{{ route('notices.show', $notice) }}" class="text-indigo-600 hover:underline">{{ __('View') }}</a>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="px-4 py-8 text-center text-gray-500">{{ __('No notices yet.') }}</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
                <div class="px-4 py-3 border-t">{{ $notices->links() }}</div>
            </div>
        </div>
    </div>
</x-app-layout>
