<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Policies\FinancePolicy;
use App\Services\Finance\PdfReportExporter;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response as SymfonyResponse;

class ReceiptController extends Controller
{
    public function __construct(
        private readonly FinancePolicy $policy,
        private readonly PdfReportExporter $pdf,
    ) {}

    public function show(Request $request, Payment $payment): View
    {
        $payment->loadMissing([
            'member.memberProfile',
            'allocations.memberDue.period',
            'allocations.memberDue.plan',
            'recordedBy',
        ]);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $payment->member), 403);

        return view('receipts.show', [
            'payment' => $payment,
            'print' => $request->boolean('print'),
            'association' => config('app.name', 'Bynnas Association'),
        ]);
    }

    public function pdf(Request $request, Payment $payment): Response|SymfonyResponse
    {
        $payment->loadMissing([
            'member.memberProfile',
            'allocations.memberDue.period',
            'allocations.memberDue.plan',
            'recordedBy',
        ]);
        abort_unless($this->policy->viewMemberFinancial($request->user(), $payment->member), 403);
        abort_unless($this->policy->exportReports($request->user()) || $request->user()->id === $payment->user_id, 403);

        return $this->pdf->download('receipts.pdf', [
            'payment' => $payment,
            'association' => config('app.name', 'Bynnas Association'),
            'generated_at' => now()->toDateTimeString(),
        ], 'receipt-'.$payment->receipt_number.'.pdf', 'portrait');
    }
}
