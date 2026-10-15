<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\StaffUserService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Throwable;

class StaffUserController extends Controller
{
    public function __construct(
        private readonly StaffUserService $staffUsers,
    ) {}

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(UserRole::SuperAdmin), 403);

        $users = User::query()
            ->whereIn('role', [UserRole::Admin, UserRole::Accountant, UserRole::SuperAdmin])
            ->orderBy('name')
            ->get();

        return response()->json([
            'data' => $users->map(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'role' => $u->role?->value,
                'is_active' => $u->is_active,
            ]),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()?->hasRole(UserRole::SuperAdmin), 403);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'role' => ['required', Rule::in([UserRole::Admin->value, UserRole::Accountant->value])],
            'password' => ['nullable', 'confirmed', Password::defaults()],
        ]);

        try {
            $result = $this->staffUsers->createStaff($request->user(), $data);
        } catch (Throwable $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'data' => [
                'id' => $result['user']->id,
                'name' => $result['user']->name,
                'email' => $result['user']->email,
                'role' => $result['user']->role?->value,
            ],
            'temporary_password' => $result['temporary_password'],
            'message' => 'Staff account created.',
        ], 201);
    }
}
