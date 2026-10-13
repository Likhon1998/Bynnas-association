@php($member = $member ?? null)

<div>
    <x-input-label for="name" :value="__('Full name')" />
    <x-text-input id="name" name="name" class="block mt-1 w-full" type="text" :value="old('name', $member?->name)" required autofocus />
    <x-input-error :messages="$errors->get('name')" class="mt-2" />
</div>

<div>
    <x-input-label for="email" :value="__('Email')" />
    <x-text-input id="email" name="email" class="block mt-1 w-full" type="email" :value="old('email', $member?->email)" required />
    <x-input-error :messages="$errors->get('email')" class="mt-2" />
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
        <x-input-label for="password" :value="__('Password')" />
        <x-text-input id="password" name="password" class="block mt-1 w-full" type="password" autocomplete="new-password" />
        <p class="mt-1 text-xs text-gray-500">{{ __('Leave blank to auto-generate (create) or keep current (edit).') }}</p>
        <x-input-error :messages="$errors->get('password')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="password_confirmation" :value="__('Confirm password')" />
        <x-text-input id="password_confirmation" name="password_confirmation" class="block mt-1 w-full" type="password" autocomplete="new-password" />
    </div>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
        <x-input-label for="phone" :value="__('Phone')" />
        <x-text-input id="phone" name="phone" class="block mt-1 w-full" type="text" :value="old('phone', $member?->memberProfile?->phone)" />
        <x-input-error :messages="$errors->get('phone')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="joined_on" :value="__('Joined on')" />
        <x-text-input id="joined_on" name="joined_on" class="block mt-1 w-full" type="date" :value="old('joined_on', optional($member?->memberProfile?->joined_on)->format('Y-m-d'))" />
        <x-input-error :messages="$errors->get('joined_on')" class="mt-2" />
    </div>
</div>

<div>
    <x-input-label for="address" :value="__('Address')" />
    <textarea id="address" name="address" rows="2" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">{{ old('address', $member?->memberProfile?->address) }}</textarea>
    <x-input-error :messages="$errors->get('address')" class="mt-2" />
</div>

<div>
    <x-input-label for="notes" :value="__('Internal notes')" />
    <textarea id="notes" name="notes" rows="3" class="border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm mt-1 block w-full">{{ old('notes', $member?->memberProfile?->notes) }}</textarea>
    <x-input-error :messages="$errors->get('notes')" class="mt-2" />
</div>
