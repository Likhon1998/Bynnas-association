<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ReportFilterRequest;
use App\Policies\FinancePolicy;
use App\Services\Finance\PdfReportExporter;
use App\Services\Finance\ReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Symfony\Component\HttpFoundation\Response as SymfonyResponse;

class ReportController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly PdfReportExporter $pdf,
        private readonly FinancePolicy $policy,
    ) {}

    public function memberWise(ReportFilterRequest $request): JsonResponse
    {
        $data = $request->validated();
        $report = $this->reports->memberWiseReport(
            from: $data['from'] ?? null,
            to: $data['to'] ?? null,
            search: $data['search'] ?? null,
            perPage: min(max((int) ($data['per_page'] ?? 15), 1), 100),
        );

        return response()->json([
            'data' => $report['rows']->items(),
            'summary' => $report['summary'],
            'meta' => [
                'current_page' => $report['rows']->currentPage(),
                'last_page' => $report['rows']->lastPage(),
                'per_page' => $report['rows']->perPage(),
                'total' => $report['rows']->total(),
            ],
        ]);
    }

    public function monthWise(ReportFilterRequest $request): JsonResponse
    {
        $data = $request->validated();
        $report = $this->reports->monthWiseReport(
            from: $data['from'] ?? null,
            to: $data['to'] ?? null,
            perPage: min(max((int) ($data['per_page'] ?? 15), 1), 100),
        );

        return response()->json([
            'data' => $report['rows']->items(),
            'summary' => $report['summary'],
            'meta' => [
                'current_page' => $report['rows']->currentPage(),
                'last_page' => $report['rows']->lastPage(),
                'per_page' => $report['rows']->perPage(),
                'total' => $report['rows']->total(),
            ],
        ]);
    }

    public function exportMemberWisePdf(Request $request): Response|SymfonyResponse
    {
        abort_unless($this->policy->exportReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $search = $request->string('search')->toString() ?: null;

        $export = $this->reports->memberWiseExport($from, $to, $search);

        return $this->pdf->download('reports.pdf.member-wise', [
            'title' => 'Member-wise contribution report',
            'rows' => $export['rows'],
            'summary' => $export['summary'],
            'generated_at' => now()->toDateTimeString(),
        ], 'member-wise-report.pdf');
    }

    public function exportMonthWisePdf(Request $request): Response|SymfonyResponse
    {
        abort_unless($this->policy->exportReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;

        $export = $this->reports->monthWiseExport($from, $to);

        return $this->pdf->download('reports.pdf.month-wise', [
            'title' => 'Month-wise contribution report',
            'rows' => $export['rows'],
            'summary' => $export['summary'],
            'generated_at' => now()->toDateTimeString(),
        ], 'month-wise-report.pdf');
    }
}
