<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\MemberResource;
use App\Models\User;
use App\Policies\MemberPolicy;
use App\Services\MemberService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MemberPhotoController extends Controller
{
    public function __construct(
        private readonly MemberService $members,
        private readonly MemberPolicy $policy,
    ) {}

    public function store(Request $request, User $member): MemberResource
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->update($request->user(), $member), 403);

        $request->validate([
            'photo' => ['required', 'image', 'max:2048'],
        ]);

        $path = $request->file('photo')->store('member-photos', 'public');
        $profile = $member->memberProfile()->firstOrCreate([]);

        if (filled($profile->photo_path)) {
            Storage::disk('public')->delete($profile->photo_path);
        }

        $updated = $this->members->update($member, ['photo_path' => $path]);

        return new MemberResource($updated);
    }
}
