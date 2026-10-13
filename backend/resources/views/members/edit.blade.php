<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Edit member') }} — {{ $member->member_id }}
        </h2>
    </x-slot>

    <div class="py-8">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="POST" action="{{ route('members.update', $member) }}" class="space-y-4">
                    @csrf
                    @method('PUT')
                    @include('members._form', ['member' => $member])
                    <div class="flex items-center justify-end gap-3 pt-2">
                        <a href="{{ route('members.show', $member) }}" class="text-sm text-gray-600 hover:underline">{{ __('Cancel') }}</a>
                        <x-primary-button>{{ __('Save changes') }}</x-primary-button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
