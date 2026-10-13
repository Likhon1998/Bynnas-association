<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Expected dues') }}</p>
        <p class="mt-1 text-2xl font-semibold text-gray-900">{{ $summary['expected_dues'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Actual collections') }}</p>
        <p class="mt-1 text-2xl font-semibold text-emerald-700">{{ $summary['actual_collections'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Allocated to dues') }}</p>
        <p class="mt-1 text-2xl font-semibold text-gray-900">{{ $summary['allocated_to_dues'] }}</p>
    </div>
    <div class="bg-white shadow-sm sm:rounded-lg p-4">
        <p class="text-xs uppercase tracking-wide text-gray-500">{{ __('Outstanding') }}</p>
        <p class="mt-1 text-2xl font-semibold text-amber-700">{{ $summary['outstanding'] }}</p>
    </div>
</div>
<p class="text-xs text-gray-500">{{ __('Summary totals are computed on the server for the full filtered set, not the current page.') }}</p>
