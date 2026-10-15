<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class MemberService
{
    public function __construct(
        private readonly MemberIdGenerator $memberIdGenerator,
    ) {}

    /**
     * @param  array{
     *     name: string,
     *     email: string,
     *     password?: string|null,
     *     phone?: string|null,
     *     address?: string|null,
     *     occupation?: string|null,
     *     notes?: string|null,
     *     joined_on?: string|null,
     * }  $data
     * @return array{member: User, temporary_password: string|null}
     */
    public function create(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $temporaryPassword = $data['password'] ?? Str::password(12);

            $member = User::query()->create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make($temporaryPassword),
                'role' => UserRole::Member,
                'member_id' => $this->memberIdGenerator->generate(),
                'is_active' => true,
                'email_verified_at' => now(),
            ]);

            $member->memberProfile()->create([
                'phone' => $data['phone'] ?? null,
                'address' => $data['address'] ?? null,
                'occupation' => $data['occupation'] ?? null,
                'notes' => $data['notes'] ?? null,
                'joined_on' => $data['joined_on'] ?? now()->toDateString(),
            ]);

            return [
                'member' => $member->load('memberProfile'),
                'temporary_password' => array_key_exists('password', $data) && filled($data['password'])
                    ? null
                    : $temporaryPassword,
            ];
        });
    }

    /**
     * @param  array{
     *     name?: string,
     *     email?: string,
     *     phone?: string|null,
     *     address?: string|null,
     *     occupation?: string|null,
     *     photo_path?: string|null,
     *     notes?: string|null,
     *     joined_on?: string|null,
     *     password?: string|null,
     * }  $data
     */
    public function update(User $member, array $data): User
    {
        return DB::transaction(function () use ($member, $data) {
            $userFields = array_filter([
                'name' => $data['name'] ?? null,
                'email' => $data['email'] ?? null,
            ], fn ($value) => $value !== null);

            if (! empty($data['password'])) {
                $userFields['password'] = Hash::make($data['password']);
            }

            if ($userFields !== []) {
                $member->fill($userFields)->save();
            }

            $profile = $member->memberProfile()->firstOrCreate([]);

            $profile->fill([
                'phone' => array_key_exists('phone', $data) ? $data['phone'] : $profile->phone,
                'address' => array_key_exists('address', $data) ? $data['address'] : $profile->address,
                'occupation' => array_key_exists('occupation', $data) ? $data['occupation'] : $profile->occupation,
                'photo_path' => array_key_exists('photo_path', $data) ? $data['photo_path'] : $profile->photo_path,
                'notes' => array_key_exists('notes', $data) ? $data['notes'] : $profile->notes,
                'joined_on' => array_key_exists('joined_on', $data) ? $data['joined_on'] : $profile->joined_on,
            ])->save();

            return $member->refresh()->load('memberProfile');
        });
    }

    public function deactivate(User $member): User
    {
        $member->deactivate();
        $member->tokens()->delete();

        return $member->refresh()->load('memberProfile');
    }

    public function reactivate(User $member): User
    {
        $member->reactivate();

        return $member->refresh()->load('memberProfile');
    }

    public function paginate(?string $search = null, ?string $status = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = User::query()
            ->with('memberProfile')
            ->where('role', UserRole::Member)
            ->latest('id');

        if (filled($search)) {
            $term = '%'.$search.'%';
            $query->where(function ($builder) use ($term) {
                $builder->where('name', 'like', $term)
                    ->orWhere('email', 'like', $term)
                    ->orWhere('member_id', 'like', $term)
                    ->orWhereHas('memberProfile', function ($profile) use ($term) {
                        $profile->where('phone', 'like', $term);
                    });
            });
        }

        if ($status === 'active') {
            $query->where('is_active', true);
        } elseif ($status === 'inactive') {
            $query->where('is_active', false);
        }

        return $query->paginate($perPage)->withQueryString();
    }

    public function findMemberOrFail(int $id): User
    {
        return User::query()
            ->with('memberProfile')
            ->where('role', UserRole::Member)
            ->whereKey($id)
            ->firstOrFail();
    }
}
