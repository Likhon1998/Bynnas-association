@php
    $audience = old('audience_type', isset($notice) ? $notice->audience_type->value : 'all_active_members');
@endphp

<div>
    <x-input-label for="title" :value="__('Title')" />
    <x-text-input id="title" name="title" class="block mt-1 w-full" :value="old('title', $notice->title ?? '')" required />
    <x-input-error :messages="$errors->get('title')" class="mt-2" />
</div>

<div>
    <x-input-label for="body" :value="__('Message')" />
    <textarea id="body" name="body" rows="6" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full" required>{{ old('body', $notice->body ?? '') }}</textarea>
    <x-input-error :messages="$errors->get('body')" class="mt-2" />
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
        <x-input-label for="audience_type" :value="__('Audience')" />
        <select id="audience_type" name="audience_type" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full" required>
            <option value="all_active_members" @selected($audience === 'all_active_members')>{{ __('All active members') }}</option>
            <option value="selected_members" @selected($audience === 'selected_members')>{{ __('Selected members') }}</option>
            <option value="role" @selected($audience === 'role')>{{ __('By role') }}</option>
        </select>
        <x-input-error :messages="$errors->get('audience_type')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="audience_role" :value="__('Role (when audience = role)')" />
        <select id="audience_role" name="audience_role" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">
            <option value="member" @selected(old('audience_role', $notice->audience_role ?? 'member') === 'member')>Member</option>
            <option value="accountant" @selected(old('audience_role', $notice->audience_role ?? '') === 'accountant')>Accountant</option>
            <option value="admin" @selected(old('audience_role', $notice->audience_role ?? '') === 'admin')>Admin</option>
        </select>
    </div>
</div>

<div>
    <x-input-label for="member_ids" :value="__('Selected members')" />
    <select id="member_ids" name="member_ids[]" multiple size="8" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">
        @foreach ($members as $member)
            <option value="{{ $member->id }}" @selected(in_array($member->id, old('member_ids', $selectedIds ?? []), true))>
                {{ $member->name }} ({{ $member->member_id }})
            </option>
        @endforeach
    </select>
    <p class="text-xs text-gray-500 mt-1">{{ __('Hold Ctrl/Cmd to multi-select. Used only when audience is selected members.') }}</p>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
        <x-input-label for="publish_at" :value="__('Publication date')" />
        <x-text-input id="publish_at" name="publish_at" type="datetime-local" class="block mt-1 w-full"
            :value="old('publish_at', isset($notice) && $notice->publish_at ? $notice->publish_at->format('Y-m-d\\TH:i') : '')" />
    </div>
    <div>
        <x-input-label for="expires_at" :value="__('Expiry date (optional)')" />
        <x-text-input id="expires_at" name="expires_at" type="datetime-local" class="block mt-1 w-full"
            :value="old('expires_at', isset($notice) && $notice->expires_at ? $notice->expires_at->format('Y-m-d\\TH:i') : '')" />
    </div>
</div>
