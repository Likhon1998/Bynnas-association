<?php

namespace App\Services\Finance;

use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Response;

class PdfReportExporter
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function download(string $view, array $data, string $filename, string $orientation = 'landscape'): Response
    {
        return Pdf::loadView($view, $data)
            ->setPaper('a4', $orientation)
            ->download($filename);
    }
}
