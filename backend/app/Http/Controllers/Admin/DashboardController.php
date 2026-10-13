<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Policies\FinancePolicy;
use App\Services\Finance\ReportService;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly FinancePolicy $policy,
    ) {}

    public function __invoke(Request $request): View
    {
        $actor = $request->user();
        abort_unless($this->policy->viewDashboard($actor) && $actor->isStaff(), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $summary = $this->reports->dashboardSummary($from, $to);

        $variant = match ($actor->role) {
            UserRole::Accountant => 'accountant',
            UserRole::SuperAdmin => 'super_admin',
            default => 'admin',
        };

        return view('dashboard', [
            'summary' => $summary,
            'variant' => $variant,
            'from' => $from,
            'to' => $to,
            'headline' => match ($variant) {
                'accountant' => 'Collections & outstanding',
                'super_admin' => 'Association overview',
                default => 'Admin overview',
            },
            'canManagePayments' => $this->policy->recordPayment($actor),
        ]);
    }
}
