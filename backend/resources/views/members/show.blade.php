<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between gap-4">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ $member->name }}
            </h2>
            <div class="flex items-center gap-2 flex-wrap">
                @if ($balance)
                    <a href="{{ route('members.statement', $member) }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">
                        {{ __('Statement') }}
                    </a>
                    <a href="{{ route('payments.create', ['member' => $member->id]) }}" class="inline-flex items-center px-4 py-2 bg-emerald-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-emerald-500">
                        {{ __('Record payment') }}
                    </a>
                @endif
                @if (auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                    <a href="{{ route('members.edit', $member) }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">
                        {{ __('Edit') }}
                    </a>
                    @if ($member->is_active)
                        <form method="POST" action="{{ route('members.deactivate', $member) }}" onsubmit="return confirm('Deactivate this member? Financial history will be preserved.');">
                            @csrf
                            <x-danger-button type="submit">{{ __('Deactivate') }}</x-danger-button>
                        </form>
                    @else
                        <form method="POST" action="{{ route('members.reactivate', $member) }}">
                            @csrf
                            <x-primary-button type="submit">{{ __('Reactivate') }}</x-primary-button>
                        </form>
                    @endif
                @endif
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-6xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">
                    {{ session('status') }}
                </div>
            @endif

            @if (session('temporary_password'))
                <div class="bg-amber-50 border border-amber-200 text-amber-900 rounded-lg px-4 py-3">
                    {{ __('Temporary password (share securely, shown once):') }}
                    <code class="font-mono font-semibold">{{ session('temporary_password') }}</code>
                </div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6 space-y-4">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                        <div class="text-gray-500">{{ __('Member ID') }}</div>
                        <div class="font-semibold text-gray-900">{{ $member->member_id }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Status') }}</div>
                        <div class="font-semibold text-gray-900">{{ $member->is_active ? __('Active') : __('Inactive') }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Email') }}</div>
                        <div class="font-semibold text-gray-900">{{ $member->email }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Phone') }}</div>
                        <div class="font-semibold text-gray-900">{{ $member->memberProfile?->phone ?: '—' }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Joined on') }}</div>
                        <div class="font-semibold text-gray-900">{{ optional($member->memberProfile?->joined_on)->format('Y-m-d') ?: '—' }}</div>
                    </div>
                    <div class="md:col-span-2">
                        <div class="text-gray-500">{{ __('Address') }}</div>
                        <div class="font-semibold text-gray-900">{{ $member->memberProfile?->address ?: '—' }}</div>
                    </div>
                    <div class="md:col-span-2">
                        <div class="text-gray-500">{{ __('Internal notes') }}</div>
                        <div class="font-semibold text-gray-900 whitespace-pre-wrap">{{ $member->memberProfile?->notes ?: '—' }}</div>
                    </div>
                </div>
            </div>

            @if ($balance)
                <div class="bg-white shadow-sm sm:rounded-lg p-6">
                    <form method="GET" class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                        <div>
                            <x-input-label for="from" :value="__('From')" />
                            <x-text-input id="from" name="from" type="date" class="block mt-1 w-full" :value="$from" />
                        </div>
                        <div>
                            <x-input-label for="to" :value="__('To')" />
                            <x-text-input id="to" name="to" type="date" class="block mt-1 w-full" :value="$to" />
                        </div>
                        <div>
                            <x-input-label for="year" :value="__('Contribution year')" />
                            <x-text-input id="year" name="year" type="number" class="block mt-1 w-full" :value="$year" placeholder="2026" />
                        </div>
                        <div class="flex items-end">
                            <x-primary-button>{{ __('Filter finances') }}</x-primary-button>
                        </div>
                    </form>

                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <div class="rounded-lg bg-slate-50 p-4">
                            <p class="text-xs uppercase text-gray-500">{{ __('Expected') }}</p>
                            <p class="text-2xl font-semibold">৳ {{ $statement['summary']['expected_dues'] ?? $balance['total_due'] }}</p>
                        </div>
                        <div class="rounded-lg bg-emerald-50 p-4">
                            <p class="text-xs uppercase text-emerald-700">{{ __('Paid') }}</p>
                            <p class="text-2xl font-semibold text-emerald-900">৳ {{ $statement['summary']['total_paid'] ?? $balance['total_allocated'] }}</p>
                        </div>
                        <div class="rounded-lg bg-amber-50 p-4">
                            <p class="text-xs uppercase text-amber-700">{{ __('Outstanding') }}</p>
                            <p class="text-2xl font-semibold text-amber-900">৳ {{ $statement['summary']['outstanding'] ?? $balance['outstanding'] }}</p>
                        </div>
                    </div>
                </div>

                @if ($statement)
                    @include('statements.partials.tables', ['statement' => $statement])
                @endif
            @endif

            <a href="{{ route('members.index') }}" class="text-sm text-indigo-600 hover:underline">{{ __('Back to members') }}</a>
        </div>
    </div>
</x-app-layout>
