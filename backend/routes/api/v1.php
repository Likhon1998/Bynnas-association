<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BackupController;
use App\Http\Controllers\Api\V1\ContributionPlanController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\DeviceTokenController;
use App\Http\Controllers\Api\V1\DueController;
use App\Http\Controllers\Api\V1\FinancialApprovalController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\MemberController;
use App\Http\Controllers\Api\V1\MemberPhotoController;
use App\Http\Controllers\Api\V1\NoticeController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SmsController;
use App\Http\Controllers\Api\V1\StaffUserController;
use App\Http\Controllers\Api\V1\StatementController;
use App\Models\User;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class);

/*
| Deliberate fault endpoints for Flutter integration tests only.
| Never enable ENABLE_INTEGRATION_FAULTS in production.
*/
if (filter_var(env('ENABLE_INTEGRATION_FAULTS', false), FILTER_VALIDATE_BOOLEAN)) {
    Route::get('/testing/server-error', function () {
        abort(500, 'Integration deliberate server error.');
    });

    Route::get('/testing/integration-info', function () {
        return response()->json([
            'app_env' => app()->environment(),
            'db_database' => config('database.connections.sqlite.database'),
            'db_default' => config('database.default'),
            'users' => User::query()->count(),
            'member_email_present' => User::query()
                ->where('email', env('INTEGRATION_MEMBER_EMAIL', 'integration.member@bynnas.test'))
                ->exists(),
            'faults_enabled' => true,
        ]);
    });
}

Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:login');

    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])
        ->middleware('throttle:6,1');

    Route::post('/reset-password', [AuthController::class, 'resetPassword'])
        ->middleware('throttle:6,1');

    Route::middleware(['auth:sanctum', 'active'])->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/logout-all', [AuthController::class, 'logoutAll']);
    });
});

Route::middleware(['auth:sanctum', 'active'])->group(function () {
    Route::get('/members/me', [MemberController::class, 'me']);

    Route::get('/members', [MemberController::class, 'index']);
    Route::post('/members', [MemberController::class, 'store']);
    Route::get('/members/{member}', [MemberController::class, 'show']);
    Route::put('/members/{member}', [MemberController::class, 'update']);
    Route::patch('/members/{member}', [MemberController::class, 'update']);
    Route::post('/members/{member}/deactivate', [MemberController::class, 'deactivate']);
    Route::post('/members/{member}/reactivate', [MemberController::class, 'reactivate']);
    Route::post('/members/{member}/photo', [MemberPhotoController::class, 'store']);

    // Contribution plans & assignments
    Route::get('/contribution-plans', [ContributionPlanController::class, 'index']);
    Route::post('/contribution-plans', [ContributionPlanController::class, 'store']);
    Route::get('/contribution-plans/{contributionPlan}', [ContributionPlanController::class, 'show']);
    Route::put('/contribution-plans/{contributionPlan}', [ContributionPlanController::class, 'update']);
    Route::patch('/contribution-plans/{contributionPlan}', [ContributionPlanController::class, 'update']);
    Route::post('/contribution-assignments', [ContributionPlanController::class, 'assign']);

    // Dues & balances
    Route::get('/dues', [DueController::class, 'index']);
    Route::post('/dues/generate', [DueController::class, 'generate']);
    Route::post('/dues/{due}/void', [DueController::class, 'void']);
    Route::get('/balances/me', [DueController::class, 'myBalance']);
    Route::get('/balances/{member}', [DueController::class, 'balance']);

    // Payments
    Route::get('/payments', [PaymentController::class, 'index']);
    Route::post('/payments', [PaymentController::class, 'store']);
    Route::get('/payments/{payment}', [PaymentController::class, 'show']);
    Route::post('/payments/{payment}/reverse', [PaymentController::class, 'reverse']);
    Route::post('/payments/{payment}/reverse-request', [FinancialApprovalController::class, 'requestReverse']);
    Route::get('/financial-approvals', [FinancialApprovalController::class, 'index']);
    Route::post('/financial-approvals/{financialChangeRequest}/approve', [FinancialApprovalController::class, 'approve']);
    Route::post('/financial-approvals/{financialChangeRequest}/reject', [FinancialApprovalController::class, 'reject']);

    // Dashboard & reports (totals computed server-side)
    Route::get('/dashboard', [DashboardController::class, 'show']);
    Route::get('/statements/me', [StatementController::class, 'me']);
    Route::get('/statements/{member}', [StatementController::class, 'show']);
    Route::get('/reports/member-wise', [ReportController::class, 'memberWise']);
    Route::get('/reports/month-wise', [ReportController::class, 'monthWise']);
    Route::get('/reports/current-month-status', [ReportController::class, 'currentMonthStatus']);
    Route::get('/reports/member-wise/pdf', [ReportController::class, 'exportMemberWisePdf']);
    Route::get('/reports/month-wise/pdf', [ReportController::class, 'exportMonthWisePdf']);

    // SMS broadcast + delivery reports
    Route::get('/sms', [SmsController::class, 'index']);
    Route::post('/sms', [SmsController::class, 'store']);
    Route::get('/sms/{smsMessage}', [SmsController::class, 'show']);

    // Super Admin staff accounts + backups
    Route::get('/staff-users', [StaffUserController::class, 'index']);
    Route::post('/staff-users', [StaffUserController::class, 'store']);
    Route::get('/backups', [BackupController::class, 'index']);
    Route::post('/backups', [BackupController::class, 'store']);

    // Notices (members see intended only; staff manage drafts/publish)
    Route::get('/notices', [NoticeController::class, 'index']);
    Route::post('/notices', [NoticeController::class, 'store']);
    Route::get('/notices/{notice}', [NoticeController::class, 'show']);
    Route::put('/notices/{notice}', [NoticeController::class, 'update']);
    Route::patch('/notices/{notice}', [NoticeController::class, 'update']);
    Route::post('/notices/{notice}/preview', [NoticeController::class, 'preview']);
    Route::post('/notices/{notice}/publish', [NoticeController::class, 'publish']);
    Route::post('/notices/{notice}/archive', [NoticeController::class, 'archive']);

    // In-app notifications + device tokens (FCM registration)
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
    Route::post('/device-tokens', [DeviceTokenController::class, 'store']);
    Route::delete('/device-tokens', [DeviceTokenController::class, 'destroy']);
});

/*
| Staff-only probe used by authorization tests and future admin API clients.
| Members receive 403.
*/
Route::middleware(['auth:sanctum', 'active', 'role:super_admin,admin,accountant'])
    ->get('/staff/ping', function () {
        return response()->json([
            'message' => 'Staff access granted.',
        ]);
    });
