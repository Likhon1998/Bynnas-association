<?php

namespace App\Http\Controllers\Admin;

use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Policies\FinancePolicy;
use App\Services\Finance\CsvReportExporter;
use App\Services\Finance\PaymentService;
use App\Services\Finance\PdfReportExporter;
use App\Services\Finance\ReportService;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response as SymfonyResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function __construct(
        private readonly ReportService $reports,
        private readonly PdfReportExporter $pdf,
        private readonly CsvReportExporter $csv,
        private readonly PaymentService $payments,
        private readonly FinancePolicy $policy,
    ) {}

    public function memberWise(Request $request): View
    {
        abort_unless($this->policy->viewReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $search = $request->string('search')->toString() ?: null;
        $print = $request->boolean('print');

        $report = $this->reports->memberWiseReport(
            from: $from,
            to: $to,
            search: $search,
            perPage: $print ? 3000 : 15,
        );

        return view($print ? 'reports.print.member-wise' : 'reports.member-wise', [
            'rows' => $report['rows'],
            'summary' => $report['summary'],
            'from' => $from,
            'to' => $to,
            'search' => $search,
        ]);
    }

    public function monthWise(Request $request): View
    {
        abort_unless($this->policy->viewReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $print = $request->boolean('print');

        $report = $this->reports->monthWiseReport(
            from: $from,
            to: $to,
            perPage: $print ? 120 : 15,
        );

        return view($print ? 'reports.print.month-wise' : 'reports.month-wise', [
            'rows' => $report['rows'],
            'summary' => $report['summary'],
            'from' => $from,
            'to' => $to,
        ]);
    }

    public function exportMemberWisePdf(Request $request): Response|SymfonyResponse
    {
        abort_unless($this->policy->exportReports($request->user()), 403);

        $export = $this->reports->memberWiseExport(
            $request->string('from')->toString() ?: null,
            $request->string('to')->toString() ?: null,
            $request->string('search')->toString() ?: null,
        );

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

        $export = $this->reports->monthWiseExport(
            $request->string('from')->toString() ?: null,
            $request->string('to')->toString() ?: null,
        );

        return $this->pdf->download('reports.pdf.month-wise', [
            'title' => 'Month-wise contribution report',
            'rows' => $export['rows'],
            'summary' => $export['summary'],
            'generated_at' => now()->toDateTimeString(),
        ], 'month-wise-report.pdf');
    }

    public function exportMemberWiseCsv(Request $request): StreamedResponse
    {
        abort_unless($this->policy->exportReports($request->user()), 403);

        $export = $this->reports->memberWiseExport(
            $request->string('from')->toString() ?: null,
            $request->string('to')->toString() ?: null,
            $request->string('search')->toString() ?: null,
        );

        return $this->csv->download(
            'member-wise-report.csv',
            ['Member ID', 'Name', 'Email', 'Expected', 'Collected', 'Allocated', 'Outstanding', 'Pending', 'Partial', 'Paid'],
            $export['rows']->map(fn (array $row) => [
                $row['member_id'],
                $row['name'],
                $row['email'],
                $row['expected_dues'],
                $row['actual_collections'],
                $row['allocated_to_dues'],
                $row['outstanding'],
                $row['payment_status']['pending'],
                $row['payment_status']['partial'],
                $row['payment_status']['paid'],
            ]),
        );
    }

    public function exportMonthWiseCsv(Request $request): StreamedResponse
    {
        abort_unless($this->policy->exportReports($request->user()), 403);

        $export = $this->reports->monthWiseExport(
            $request->string('from')->toString() ?: null,
            $request->string('to')->toString() ?: null,
        );

        return $this->csv->download(
            'month-wise-report.csv',
            ['Period', 'Year', 'Month', 'Expected', 'Collected', 'Allocated', 'Outstanding', 'Pending', 'Partial', 'Paid'],
            $export['rows']->map(fn (array $row) => [
                $row['label'],
                $row['year'],
                $row['month'],
                $row['expected_dues'],
                $row['actual_collections'],
                $row['allocated_to_dues'],
                $row['outstanding'],
                $row['payment_status']['pending'],
                $row['payment_status']['partial'],
                $row['payment_status']['paid'],
            ]),
        );
    }

    public function paymentRegister(Request $request): View
    {
        abort_unless($this->policy->viewReports($request->user()), 403);

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $status = $request->string('status')->toString() ?: null;

        $payments = $this->payments->paginateAll(
            perPage: 25,
            filters: [
                'from' => $from,
                'to' => $to,
                'status' => $status,
                'search' => $request->string('search')->toString() ?: null,
            ],
        );

        return view('reports.payment-register', [
            'payments' => $payments,
            'from' => $from,
            'to' => $to,
            'status' => $status,
            'search' => $request->string('search')->toString(),
            'statuses' => PaymentStatus::cases(),
        ]);
    }

    public function reversedPayments(Request $request): View
    {
        abort_unless($this->policy->viewReports($request->user()), 403);

        $payments = $this->payments->paginateAll(
            perPage: 25,
            filters: [
                'status' => PaymentStatus::Reversed->value,
                'from' => $request->string('from')->toString() ?: null,
                'to' => $request->string('to')->toString() ?: null,
                'search' => $request->string('search')->toString() ?: null,
            ],
        );

        return view('reports.reversed-payments', [
            'payments' => $payments,
            'from' => $request->string('from')->toString(),
            'to' => $request->string('to')->toString(),
            'search' => $request->string('search')->toString(),
        ]);
    }
}
