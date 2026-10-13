<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * The association UI is mobile-only. Web sessions are not an admin console.
 */
class MobileOnlyController extends Controller
{
    public function __invoke(Request $request): View
    {
        return view('mobile-only', [
            'authenticated' => $request->user() !== null,
            'user' => $request->user(),
        ]);
    }
}
