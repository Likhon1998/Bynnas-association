<?php

namespace App\Http\Controllers\Admin;

use App\Enums\NoticeAudienceType;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Notice;
use App\Models\User;
use App\Policies\NoticePolicy;
use App\Services\Notices\NoticeService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Throwable;

class NoticeController extends Controller
{
    public function __construct(
        private readonly NoticeService $notices,
        private readonly NoticePolicy $policy,
    ) {}

    public function index(Request $request): View
    {
        abort_unless($this->policy->viewAny($request->user()) && $request->user()->isStaff(), 403);

        return view('notices.index', [
            'notices' => $this->notices->paginateForStaff(
                status: $request->string('status')->toString() ?: null,
            ),
            'status' => $request->string('status')->toString(),
        ]);
    }

    public function create(Request $request): View
    {
        abort_unless($this->policy->create($request->user()), 403);

        return view('notices.create', [
            'members' => User::query()
                ->where('role', UserRole::Member)
                ->where('is_active', true)
                ->orderBy('name')
                ->limit(500)
                ->get(['id', 'name', 'member_id']),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($this->policy->create($request->user()), 403);

        $validated = $this->validatedPayload($request);

        try {
            $notice = $this->notices->create($request->user(), $validated);
        } catch (Throwable $e) {
            return back()->withInput()->withErrors(['audience_type' => $e->getMessage()]);
        }

        return redirect()
            ->route('notices.show', $notice)
            ->with('status', 'Notice drafted. Preview and publish when ready.');
    }

    public function show(Request $request, Notice $notice): View
    {
        abort_unless($this->policy->view($request->user(), $notice), 403);
        $notice->load(['targets.user', 'creator']);
        $preview = $this->notices->preview($notice);

        return view('notices.show', [
            'notice' => $notice,
            'preview' => $preview,
        ]);
    }

    public function edit(Request $request, Notice $notice): View
    {
        abort_unless($this->policy->update($request->user(), $notice), 403);
        $notice->load('targets');

        return view('notices.edit', [
            'notice' => $notice,
            'members' => User::query()
                ->where('role', UserRole::Member)
                ->where('is_active', true)
                ->orderBy('name')
                ->limit(500)
                ->get(['id', 'name', 'member_id']),
            'selectedIds' => $notice->targets->pluck('user_id')->all(),
        ]);
    }

    public function update(Request $request, Notice $notice): RedirectResponse
    {
        abort_unless($this->policy->update($request->user(), $notice), 403);

        try {
            $this->notices->update($request->user(), $notice, $this->validatedPayload($request));
        } catch (Throwable $e) {
            return back()->withInput()->withErrors(['audience_type' => $e->getMessage()]);
        }

        return redirect()->route('notices.show', $notice)->with('status', 'Notice updated.');
    }

    public function publish(Request $request, Notice $notice): RedirectResponse
    {
        abort_unless($this->policy->publish($request->user(), $notice), 403);

        try {
            $this->notices->publish($request->user(), $notice);
        } catch (Throwable $e) {
            return back()->withErrors(['publish' => $e->getMessage()]);
        }

        return redirect()->route('notices.show', $notice)->with('status', 'Notice published. Delivery queued.');
    }

    public function archive(Request $request, Notice $notice): RedirectResponse
    {
        abort_unless($this->policy->archive($request->user(), $notice), 403);
        $this->notices->archive($request->user(), $notice);

        return redirect()->route('notices.show', $notice)->with('status', 'Notice archived.');
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedPayload(Request $request): array
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string', 'max:10000'],
            'audience_type' => ['required', Rule::in(NoticeAudienceType::values())],
            'audience_role' => ['nullable', Rule::in(UserRole::values())],
            'member_ids' => ['nullable', 'array'],
            'member_ids.*' => ['integer', 'exists:users,id'],
            'publish_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:publish_at'],
        ]);

        if (($validated['audience_type'] ?? null) === NoticeAudienceType::Role->value
            && empty($validated['audience_role'])) {
            $validated['audience_role'] = UserRole::Member->value;
        }

        return $validated;
    }
}
