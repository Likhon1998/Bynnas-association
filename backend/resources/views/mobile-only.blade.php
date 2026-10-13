<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'Bynnas Association') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="antialiased bg-slate-100 text-slate-900 min-h-screen flex items-center justify-center p-6">
    <div class="max-w-lg w-full bg-white shadow-sm rounded-2xl p-8 space-y-4">
        <h1 class="text-2xl font-bold">{{ config('app.name', 'Bynnas Association') }}</h1>
        <p class="text-slate-600">
            {{ __('This product is mobile-only. Members and staff use the Flutter app. The web admin panel has been retired.') }}
        </p>
        <p class="text-sm text-slate-500">
            {{ __('API base path remains') }} <code class="font-mono">/api/v1</code>
            {{ __('for the mobile application.') }}
        </p>
        @if ($authenticated)
            <div class="rounded-lg bg-slate-50 border border-slate-200 p-4 text-sm">
                <div class="font-semibold">{{ $user?->name }}</div>
                <div class="text-slate-500">{{ $user?->email }} · {{ str_replace('_', ' ', $user?->role?->value ?? '') }}</div>
            </div>
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit" class="inline-flex items-center px-4 py-2 bg-slate-900 text-white rounded-md text-sm font-semibold">
                    {{ __('Log out') }}
                </button>
            </form>
        @else
            <a href="{{ route('login') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-semibold">
                {{ __('Staff session (info only)') }}
            </a>
        @endif
    </div>
</body>
</html>
