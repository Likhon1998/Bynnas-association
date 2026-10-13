<?php

use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\MemberController;
use App\Http\Controllers\Admin\NoticeController;
use App\Http\Controllers\Admin\PaymentController;
use App\Http\Controllers\Admin\ReceiptController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\StatementController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::middleware(['auth', 'verified', 'staff'])->group(function () {
    Route::get('/dashboard', DashboardController::class)->name('dashboard');

    Route::get('/members', [MemberController::class, 'index'])->name('members.index');
    Route::get('/members/create', [MemberController::class, 'create'])->name('members.create');
    Route::post('/members', [MemberController::class, 'store'])->name('members.store');
    Route::get('/members/{member}', [MemberController::class, 'show'])->name('members.show');
    Route::get('/members/{member}/edit', [MemberController::class, 'edit'])->name('members.edit');
    Route::put('/members/{member}', [MemberController::class, 'update'])->name('members.update');
    Route::post('/members/{member}/deactivate', [MemberController::class, 'deactivate'])->name('members.deactivate');
    Route::post('/members/{member}/reactivate', [MemberController::class, 'reactivate'])->name('members.reactivate');
    Route::get('/members/{member}/statement', [StatementController::class, 'show'])->name('members.statement');
    Route::get('/members/{member}/statement/pdf', [StatementController::class, 'pdf'])->name('members.statement.pdf');

    Route::get('/payments', [PaymentController::class, 'index'])->name('payments.index');
    Route::get('/payments/create', [PaymentController::class, 'create'])->name('payments.create');
    Route::post('/payments', [PaymentController::class, 'store'])->name('payments.store');
    Route::get('/payments/{payment}', [PaymentController::class, 'show'])->name('payments.show');
    Route::post('/payments/{payment}/reverse', [PaymentController::class, 'reverse'])->name('payments.reverse');

    Route::get('/receipts/{payment}', [ReceiptController::class, 'show'])->name('receipts.show');
    Route::get('/receipts/{payment}/pdf', [ReceiptController::class, 'pdf'])->name('receipts.pdf');

    Route::get('/reports/member-wise', [ReportController::class, 'memberWise'])->name('reports.member-wise');
    Route::get('/reports/month-wise', [ReportController::class, 'monthWise'])->name('reports.month-wise');
    Route::get('/reports/member-wise/pdf', [ReportController::class, 'exportMemberWisePdf'])->name('reports.member-wise.pdf');
    Route::get('/reports/month-wise/pdf', [ReportController::class, 'exportMonthWisePdf'])->name('reports.month-wise.pdf');
    Route::get('/reports/member-wise/csv', [ReportController::class, 'exportMemberWiseCsv'])->name('reports.member-wise.csv');
    Route::get('/reports/month-wise/csv', [ReportController::class, 'exportMonthWiseCsv'])->name('reports.month-wise.csv');
    Route::get('/reports/payment-register', [ReportController::class, 'paymentRegister'])->name('reports.payment-register');
    Route::get('/reports/reversed-payments', [ReportController::class, 'reversedPayments'])->name('reports.reversed-payments');

    Route::get('/notices', [NoticeController::class, 'index'])->name('notices.index');
    Route::get('/notices/create', [NoticeController::class, 'create'])->name('notices.create');
    Route::post('/notices', [NoticeController::class, 'store'])->name('notices.store');
    Route::get('/notices/{notice}', [NoticeController::class, 'show'])->name('notices.show');
    Route::get('/notices/{notice}/edit', [NoticeController::class, 'edit'])->name('notices.edit');
    Route::put('/notices/{notice}', [NoticeController::class, 'update'])->name('notices.update');
    Route::post('/notices/{notice}/publish', [NoticeController::class, 'publish'])->name('notices.publish');
    Route::post('/notices/{notice}/archive', [NoticeController::class, 'archive'])->name('notices.archive');
});

Route::middleware(['auth', 'staff'])->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
