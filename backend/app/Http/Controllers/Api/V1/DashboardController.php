<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\ReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly FinancePolicy $policy,
    ) {}

    public function show(Request $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();
        abort_unless($this->policy->viewDashboard($actor), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;

        if ($actor->isMember()) {
            $summary = $this->reports->dashboardSummary($from, $to, $actor);
            $summary['role'] = $actor->role->value;
            $summary['headline'] = 'My dues overview';
            $summary['capabilities'] = ['view_own_balance', 'view_own_payments'];
        } elseif ($actor->hasRole(UserRole::Accountant)) {
            $summary = $this->reports->dashboardSummary($from, $to);
            $summary['role'] = $actor->role->value;
            $summary['headline'] = 'Collections & outstanding';
            $summary['capabilities'] = ['view_reports', 'record_payments', 'export_reports'];
        } else {
            $summary = $this->reports->dashboardSummary($from, $to);
            $summary['role'] = $actor->role->value;
            $summary['headline'] = 'Association overview';
            $summary['capabilities'] = ['view_reports', 'manage_members', 'export_reports'];
        }

        return response()->json(['data' => $summary]);
    }
}
