<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
                <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Member statement') }}</h2>
                <p class="text-sm text-gray-500 mt-1">{{ $member->name }} · {{ $member->member_id }}</p>
            </div>
            <div class="flex flex-wrap gap-2">
                <a href="{{ route('members.statement', ['member' => $member, 'from' => $from, 'to' => $to, 'print' => 1]) }}" class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">{{ __('Print') }}</a>
                <a href="{{ route('members.statement.pdf', ['member' => $member, 'from' => $from, 'to' => $to]) }}" class="inline-flex items-center px-3 py-2 bg-indigo-600 border border-transparent rounded-md text-xs font-semibold uppercase tracking-widest text-white hover:bg-indigo-500">{{ __('PDF') }}</a>
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-5xl mx-auto sm:px-6 lg:px-8 space-y-4">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                        <x-input-label for="from" :value="__('From')" />
                        <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$from" />
                    </div>
                    <div>
                        <x-input-label for="to" :value="__('To')" />
                        <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$to" />
                    </div>
                    <div class="md:col-span-2 flex items-end gap-2">
                        <x-primary-button>{{ __('Apply') }}</x-primary-button>
                        <a href="{{ route('members.show', $member) }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">{{ __('Member profile') }}</a>
                    </div>
                </form>
            </div>

            @include('statements.partials.summary', ['summary' => $statement['summary']])
            @include('statements.partials.tables', ['statement' => $statement])
        </div>
    </div>
</x-app-layout>
