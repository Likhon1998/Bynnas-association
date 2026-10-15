<?php

namespace App\Providers;

use App\Contracts\PushNotificationSender;
use App\Contracts\SmsGateway;
use App\Enums\UserRole;
use App\Models\User;
use App\Policies\UserPolicy;
use App\Services\Notifications\FcmPushNotificationSender;
use App\Services\Notifications\NullPushNotificationSender;
use App\Services\Sms\LogSmsGateway;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PushNotificationSender::class, function () {
            $fcm = new FcmPushNotificationSender;

            return $fcm->isConfigured() ? $fcm : new NullPushNotificationSender;
        });

        $this->app->singleton(SmsGateway::class, LogSmsGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(User::class, UserPolicy::class);

        Gate::define('access-admin', function (User $user): bool {
            return $user->is_active && $user->isStaff();
        });

        Gate::define('manage-roles', function (User $user): bool {
            return $user->is_active && $user->hasRole(UserRole::SuperAdmin);
        });

        Route::bind('member', function (string $value) {
            return User::query()
                ->where('role', UserRole::Member)
                ->whereKey($value)
                ->firstOrFail();
        });

        RateLimiter::for('login', function (Request $request) {
            // Isolated mobile integration suite exercises many login attempts.
            if ($this->app->environment('integration')) {
                return Limit::none();
            }

            $email = (string) $request->input('email', 'unknown');

            return Limit::perMinute(5)->by(strtolower($email).'|'.$request->ip());
        });
    }
}
