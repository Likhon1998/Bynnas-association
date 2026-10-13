<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Record payment') }}</h2>
    </x-slot>

    <div class="py-8">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8 space-y-4">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form method="GET" action="{{ route('payments.create') }}" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <div class="md:col-span-2">
                        <x-input-label for="member" :value="__('Member user ID')" />
                        <x-text-input id="member" name="member" type="number" class="block mt-1 w-full" :value="optional($member)->id" required />
                        <p class="text-xs text-gray-500 mt-1">{{ __('Open from a member profile for convenience, or enter the member’s internal user ID.') }}</p>
                    </div>
                    <div class="flex items-end">
                        <x-primary-button type="submit">{{ __('Load dues') }}</x-primary-button>
                    </div>
                </form>

                @if ($member)
                    <div class="rounded-lg bg-slate-50 border border-slate-200 p-4 mb-6 text-sm">
                        <div class="font-semibold text-gray-900">{{ $member->name }}</div>
                        <div class="text-gray-600">{{ $member->member_id }} · {{ $member->email }}</div>
                    </div>

                    <form method="POST" action="{{ route('payments.store') }}" class="space-y-4" x-data="{ submitting: false }" @submit="if (submitting) { $event.preventDefault() } else { submitting = true }">
                        @csrf
                        <input type="hidden" name="user_id" value="{{ $member->id }}">
                        <input type="hidden" name="idempotency_key" value="{{ old('idempotency_key', $idempotencyKey) }}">

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <x-input-label for="amount" :value="__('Amount (BDT)')" />
                                <x-text-input id="amount" name="amount" class="block mt-1 w-full" :value="old('amount')" required />
                                <x-input-error :messages="$errors->get('amount')" class="mt-2" />
                            </div>
                            <div>
                                <x-input-label for="method" :value="__('Method')" />
                                <select id="method" name="method" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full" required>
                                    @foreach ($methods as $method)
                                        <option value="{{ $method->value }}" @selected(old('method', 'cash') === $method->value)>{{ str_replace('_', ' ', ucfirst($method->value)) }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div>
                                <x-input-label for="received_at" :value="__('Received at')" />
                                <x-text-input id="received_at" name="received_at" type="datetime-local" class="block mt-1 w-full" :value="old('received_at')" />
                            </div>
                            <div>
                                <x-input-label for="notes" :value="__('Notes')" />
                                <x-text-input id="notes" name="notes" class="block mt-1 w-full" :value="old('notes')" />
                            </div>
                        </div>

                        <div>
                            <h3 class="text-sm font-semibold text-gray-800 mb-2">{{ __('Allocations (optional — supports partial payments)') }}</h3>
                            @if ($outstandingDues->isEmpty())
                                <p class="text-sm text-gray-500">{{ __('No open dues for this member. You can still record an unallocated payment.') }}</p>
                            @else
                                <div class="space-y-3">
                                    @foreach ($outstandingDues as $index => $due)
                                        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end border border-gray-100 rounded-lg p-3">
                                            <div class="md:col-span-2 text-sm">
                                                <div class="font-medium text-gray-900">{{ $due->period?->label }}</div>
                                                <div class="text-gray-500">{{ __('Outstanding') }}: ৳ {{ $due->outstandingBalance() }}</div>
                                                <input type="hidden" name="allocations[{{ $index }}][member_due_id]" value="{{ $due->id }}">
                                            </div>
                                            <div>
                                                <x-input-label :for="'alloc_'.$due->id" :value="__('Allocate')" />
                                                <x-text-input :id="'alloc_'.$due->id" name="allocations[{{ $index }}][amount]" class="block mt-1 w-full" :value="old('allocations.'.$index.'.amount')" placeholder="0.00" />
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            @endif
                        </div>

                        <div class="flex gap-2">
                            <x-primary-button x-bind:disabled="submitting">{{ __('Save payment') }}</x-primary-button>
                            <a href="{{ route('payments.index') }}" class="inline-flex items-center px-4 py-2 bg-white border border-gray-300 rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-50">{{ __('Cancel') }}</a>
                        </div>
                    </form>
                @endif
            </div>
        </div>
    </div>
</x-app-layout>
