<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase text-gray-500">{{ __('Expected') }}</p>
        <p class="text-xl font-semibold">৳ {{ $summary['expected_dues'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase text-gray-500">{{ __('Paid') }}</p>
        <p class="text-xl font-semibold text-emerald-700">৳ {{ $summary['total_paid'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase text-gray-500">{{ __('Allocated') }}</p>
        <p class="text-xl font-semibold">৳ {{ $summary['allocated_to_dues'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase text-gray-500">{{ __('Outstanding') }}</p>
        <p class="text-xl font-semibold text-amber-700">৳ {{ $summary['outstanding'] }}</p>
    </div>
</div>
