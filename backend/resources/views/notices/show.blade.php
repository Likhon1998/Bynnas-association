<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ $notice->title }}</h2>
            <div class="flex flex-wrap gap-2">
                @if ($notice->status === \App\Enums\NoticeStatus::Draft && auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                    <a href="{{ route('notices.edit', $notice) }}" class="inline-flex items-center px-3 py-2 bg-white border border-gray-300 rounded-md text-xs font-semibold uppercase tracking-widest text-gray-700 hover:bg-gray-50">{{ __('Edit') }}</a>
                    <form method="POST" action="{{ route('notices.publish', $notice) }}">
                        @csrf
                        <x-primary-button type="submit">{{ __('Publish') }}</x-primary-button>
                    </form>
                @endif
                @if ($notice->status === \App\Enums\NoticeStatus::Published && auth()->user()->hasRole(\App\Enums\UserRole::SuperAdmin, \App\Enums\UserRole::Admin))
                    <form method="POST" action="{{ route('notices.archive', $notice) }}">
                        @csrf
                        <x-secondary-button type="submit">{{ __('Archive') }}</x-secondary-button>
                    </form>
                @endif
            </div>
        </div>
    </x-slot>

    <div class="py-8">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8 space-y-4">
            @if (session('status'))
                <div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3">{{ session('status') }}</div>
            @endif
            @if ($errors->any())
                <div class="bg-red-50 border border-red-200 text-red-800 rounded-lg px-4 py-3">{{ $errors->first() }}</div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg p-6 space-y-4 text-sm">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <div class="text-gray-500">{{ __('Status') }}</div>
                        <div class="font-semibold">{{ ucfirst($notice->status->value) }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Audience') }}</div>
                        <div class="font-semibold">{{ str_replace('_', ' ', $notice->audience_type->value) }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Publication') }}</div>
                        <div class="font-semibold">{{ $notice->publish_at?->toDateTimeString() ?: '—' }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">{{ __('Expires') }}</div>
                        <div class="font-semibold">{{ $notice->expires_at?->toDateTimeString() ?: '—' }}</div>
                    </div>
                </div>
                <div>
                    <div class="text-gray-500 mb-1">{{ __('Message') }}</div>
                    <div class="whitespace-pre-wrap text-gray-900">{{ $notice->body }}</div>
                </div>
            </div>

            <div class="bg-indigo-50 border border-indigo-100 rounded-lg p-4 text-sm text-indigo-950">
                <div class="font-semibold mb-1">{{ __('Preview before publish') }}</div>
                <p>{{ __('Estimated recipients') }}: <strong>{{ $preview['recipient_count'] }}</strong></p>
                <p class="text-xs mt-1">{{ __('Publishing queues chunked delivery jobs; the web request does not notify all members synchronously.') }}</p>
            </div>
        </div>
    </div>
</x-app-layout>
