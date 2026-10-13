<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>{{ __('Member statement') }} — {{ $member->member_id }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>@media print { .no-print { display: none !important; } }</style>
</head>
<body class="bg-white text-gray-900 p-8">
    <div class="no-print mb-4">
        <button onclick="window.print()" class="px-3 py-2 border rounded-md text-sm">{{ __('Print') }}</button>
    </div>
    <h1 class="text-2xl font-bold">{{ $association }}</h1>
    <p class="text-sm text-gray-500 mb-4">{{ __('Member statement') }} · {{ $member->name }} ({{ $member->member_id }})</p>
    @include('statements.partials.summary', ['summary' => $statement['summary']])
    @include('statements.partials.tables', ['statement' => $statement])
</body>
</html>
