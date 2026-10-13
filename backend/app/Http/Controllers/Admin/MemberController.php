<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Policies\FinancePolicy;
use App\Policies\MemberPolicy;
use App\Services\Finance\BalanceService;
use App\Services\Finance\DueService;
use App\Services\Finance\PaymentService;
use App\Services\Finance\ReportService;
use App\Services\MemberService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

class MemberController extends Controller
{
    public function __construct(
        private readonly MemberService $members,
        private readonly MemberPolicy $policy,
        private readonly FinancePolicy $financePolicy,
        private readonly BalanceService $balances,
        private readonly DueService $dues,
        private readonly PaymentService $payments,
        private readonly ReportService $reports,
    ) {}

    public function index(Request $request): View
    {
        abort_unless($this->policy->viewAny($request->user()), 403);

        $members = $this->members->paginate(
            search: $request->string('search')->toString() ?: null,
            status: $request->string('status')->toString() ?: null,
            perPage: 15,
        );

        return view('members.index', [
            'members' => $members,
            'search' => $request->string('search')->toString(),
            'status' => $request->string('status')->toString(),
        ]);
    }

    public function create(Request $request): View
    {
        abort_unless($this->policy->create($request->user()), 403);

        return view('members.create');
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($this->policy->create($request->user()), 403);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'phone' => ['nullable', 'string', 'max:32'],
            'address' => ['nullable', 'string', 'max:500'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'joined_on' => ['nullable', 'date'],
        ]);

        $result = $this->members->create($validated);

        return redirect()
            ->route('members.show', $result['member'])
            ->with('status', 'Member created successfully.')
            ->with('temporary_password', $result['temporary_password']);
    }

    public function show(Request $request, User $member): View
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->view($request->user(), $member), 403);

        $member->loadMissing('memberProfile');

        $from = $request->string('from')->toString() ?: null;
        $to = $request->string('to')->toString() ?: null;
        $year = $request->filled('year') ? (int) $request->integer('year') : null;

        $balance = null;
        $statement = null;
        $dues = null;
        $payments = null;

        if ($this->financePolicy->viewMemberFinancial($request->user(), $member)) {
            $balance = $this->balances->outstandingForMember($member);
            $statement = $this->reports->memberStatement(
                $member,
                $from ?? ($year ? sprintf('%04d-01-01', $year) : null),
                $to ?? ($year ? sprintf('%04d-12-31', $year) : null),
            );
            $dues = $this->dues->paginateForMember($member, 12);
            $payments = $this->payments->paginateForMember($member, 12);
        }

        return view('members.show', [
            'member' => $member,
            'balance' => $balance,
            'statement' => $statement,
            'dues' => $dues,
            'payments' => $payments,
            'from' => $from,
            'to' => $to,
            'year' => $year,
        ]);
    }

    public function edit(Request $request, User $member): View
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->update($request->user(), $member), 403);

        $member->loadMissing('memberProfile');

        return view('members.edit', compact('member'));
    }

    public function update(Request $request, User $member): RedirectResponse
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->update($request->user(), $member), 403);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($member->id),
            ],
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'phone' => ['nullable', 'string', 'max:32'],
            'address' => ['nullable', 'string', 'max:500'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'joined_on' => ['nullable', 'date'],
        ]);

        $this->members->update($member, $validated);

        return redirect()
            ->route('members.show', $member)
            ->with('status', 'Member updated successfully.');
    }

    public function deactivate(Request $request, User $member): RedirectResponse
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->deactivate($request->user(), $member), 403);

        $this->members->deactivate($member);

        return back()->with('status', 'Member deactivated. Financial history is preserved.');
    }

    public function reactivate(Request $request, User $member): RedirectResponse
    {
        abort_unless($member->isMember(), 404);
        abort_unless($this->policy->reactivate($request->user(), $member), 403);

        $this->members->reactivate($member);

        return back()->with('status', 'Member reactivated successfully.');
    }
}
