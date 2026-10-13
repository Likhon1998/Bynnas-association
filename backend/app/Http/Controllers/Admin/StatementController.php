<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Services\Finance\PdfReportExporter;
use App\Services\Finance\ReportService;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response as SymfonyResponse;

class StatementController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly FinancePolicy $policy,
        private readonly PdfReportExporter $pdf,
    ) {}

    public function show(Request $request, User $member): View
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $member), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $print = $request->boolean('print');
        $statement = $this->reports->memberStatement($member, $from, $to);

        return view($print ? 'statements.print' : 'statements.show', [
            'member' => $member,
            'statement' => $statement,
            'from' => $from,
            'to' => $to,
            'association' => config('app.name', 'Bynnas Association'),
        ]);
    }

    public function pdf(Request $request, User $member): Response|SymfonyResponse
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $member), 403);
        abort_unless($this->policy->exportReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $statement = $this->reports->memberStatement($member, $from, $to);

        return $this->pdf->download('statements.pdf', [
            'statement' => $statement,
            'association' => config('app.name', 'Bynnas Association'),
            'generated_at' => now()->toDateTimeString(),
        ], 'member-statement-'.($member->member_id ?? $member->id).'.pdf', 'portrait');
    }
}
