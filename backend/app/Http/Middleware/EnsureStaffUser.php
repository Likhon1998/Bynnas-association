<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureStaffUser
{
    /**
     * Restrict the web admin panel to staff roles.
     *
     * @param  Closure(Request): Response  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user === null) {
            abort(Response::HTTP_UNAUTHORIZED);
        }

        if (! $user->isStaff()) {
            if ($request->expectsJson() || $request->is('api/*')) {
                abort(Response::HTTP_FORBIDDEN, 'Members cannot access the admin panel.');
            }

            auth()->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Use the Flutter mobile application. Web admin is retired.']);
        }

        return $next($request);
    }
}
