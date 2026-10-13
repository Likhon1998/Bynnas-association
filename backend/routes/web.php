<?php

use App\Http\Controllers\MobileOnlyController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

/*
| Web UI is retired. Association workflows run in the Flutter mobile app
| against /api/v1. These routes only show a mobile-only notice (and Breeze
| auth helpers for password reset / session logout).
*/

Route::get('/', MobileOnlyController::class)->name('home');

Route::middleware(['auth', 'staff'])->group(function () {
    // Keep the dashboard route name for Breeze redirects / legacy bookmarks.
    Route::get('/dashboard', MobileOnlyController::class)->name('dashboard');

    // Former admin URLs → same notice (bookmarks / old links).
    Route::redirect('/members', '/dashboard');
    Route::redirect('/members/{member}', '/dashboard');
    Route::redirect('/payments', '/dashboard');
    Route::redirect('/payments/{payment}', '/dashboard');
    Route::redirect('/receipts/{payment}', '/dashboard');
    Route::redirect('/reports/member-wise', '/dashboard');
    Route::redirect('/reports/month-wise', '/dashboard');
    Route::redirect('/reports/payment-register', '/dashboard');
    Route::redirect('/reports/reversed-payments', '/dashboard');
    Route::redirect('/notices', '/dashboard');
    Route::redirect('/notices/{notice}', '/dashboard');

    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
