<?php

namespace App\Services\Notices;

use App\Enums\NoticeAudienceType;
use App\Enums\NoticeStatus;
use App\Enums\UserRole;
use App\Jobs\PublishNoticeJob;
use App\Models\Notice;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use LogicException;

class NoticeService
{
    /**
     * @param  array{
     *     title: string,
     *     body: string,
     *     audience_type: string,
     *     audience_role?: string|null,
     *     member_ids?: list<int>|null,
     *     publish_at?: string|null,
     *     expires_at?: string|null,
     * }  $data
     */
    public function create(User $actor, array $data): Notice
    {
        return DB::transaction(function () use ($actor, $data) {
            $audience = NoticeAudienceType::from($data['audience_type']);
            $this->assertAudience($audience, $data);

            $notice = Notice::query()->create([
                'title' => $data['title'],
                'body' => $data['body'],
                'status' => NoticeStatus::Draft,
                'audience_type' => $audience,
                'audience_role' => $audience === NoticeAudienceType::Role
                    ? ($data['audience_role'] ?? null)
                    : null,
                'publish_at' => $data['publish_at'] ?? null,
                'expires_at' => $data['expires_at'] ?? null,
                'created_by' => $actor->id,
                'updated_by' => $actor->id,
            ]);

            if ($audience === NoticeAudienceType::SelectedMembers) {
                $this->syncTargets($notice, $data['member_ids'] ?? []);
            }

            return $notice->load('targets');
        });
    }

    /**
     * @param  array{
     *     title?: string,
     *     body?: string,
     *     audience_type?: string,
     *     audience_role?: string|null,
     *     member_ids?: list<int>|null,
     *     publish_at?: string|null,
     *     expires_at?: string|null,
     * }  $data
     */
    public function update(User $actor, Notice $notice, array $data): Notice
    {
        return DB::transaction(function () use ($actor, $notice, $data) {
            $notice = Notice::query()->whereKey($notice->id)->lockForUpdate()->firstOrFail();

            if ($notice->status !== NoticeStatus::Draft) {
                throw new LogicException('Only draft notices can be edited.');
            }

            $audience = isset($data['audience_type'])
                ? NoticeAudienceType::from($data['audience_type'])
                : $notice->audience_type;

            $merged = array_merge([
                'audience_type' => $audience->value,
                'audience_role' => $data['audience_role'] ?? $notice->audience_role,
                'member_ids' => $data['member_ids'] ?? $notice->targets()->pluck('user_id')->all(),
            ], $data);

            $this->assertAudience($audience, $merged);

            $notice->fill([
                'title' => $data['title'] ?? $notice->title,
                'body' => $data['body'] ?? $notice->body,
                'audience_type' => $audience,
                'audience_role' => $audience === NoticeAudienceType::Role
                    ? ($merged['audience_role'] ?? null)
                    : null,
                'publish_at' => array_key_exists('publish_at', $data) ? $data['publish_at'] : $notice->publish_at,
                'expires_at' => array_key_exists('expires_at', $data) ? $data['expires_at'] : $notice->expires_at,
                'updated_by' => $actor->id,
            ])->save();

            if ($audience === NoticeAudienceType::SelectedMembers) {
                $this->syncTargets($notice, $merged['member_ids'] ?? []);
            } else {
                $notice->targets()->delete();
            }

            return $notice->refresh()->load('targets');
        });
    }

    /**
     * @return array{notice: Notice, recipient_count: int, sample_member_ids: list<int>}
     */
    public function preview(Notice $notice): array
    {
        $ids = $this->recipientQuery($notice)->limit(5)->pluck('id')->all();
        $count = $this->recipientQuery($notice)->count();

        return [
            'notice' => $notice,
            'recipient_count' => $count,
            'sample_member_ids' => array_map('intval', $ids),
        ];
    }

    public function publish(User $actor, Notice $notice): Notice
    {
        $notice = DB::transaction(function () use ($actor, $notice) {
            $notice = Notice::query()->whereKey($notice->id)->lockForUpdate()->firstOrFail();

            if ($notice->status === NoticeStatus::Archived) {
                throw new LogicException('Archived notices cannot be published.');
            }

            if ($notice->status === NoticeStatus::Published) {
                return $notice;
            }

            $count = $this->recipientQuery($notice)->count();
            if ($count === 0) {
                throw new LogicException('Cannot publish a notice with zero recipients.');
            }

            $notice->forceFill([
                'status' => NoticeStatus::Published,
                'published_at' => now(),
                'publish_at' => $notice->publish_at ?? now(),
                'recipient_count' => $count,
                'updated_by' => $actor->id,
            ])->save();

            return $notice->refresh();
        });

        // Fan-out asynchronously — never send 3k notifications in the HTTP request.
        PublishNoticeJob::dispatch($notice->id);

        return $notice;
    }

    public function archive(User $actor, Notice $notice): Notice
    {
        return DB::transaction(function () use ($actor, $notice) {
            $notice = Notice::query()->whereKey($notice->id)->lockForUpdate()->firstOrFail();

            if ($notice->status === NoticeStatus::Archived) {
                return $notice;
            }

            $notice->forceFill([
                'status' => NoticeStatus::Archived,
                'archived_at' => now(),
                'updated_by' => $actor->id,
            ])->save();

            return $notice->refresh();
        });
    }

    public function paginateForStaff(?string $status = null, int $perPage = 15): LengthAwarePaginator
    {
        return Notice::query()
            ->with('creator')
            ->when(filled($status), fn (Builder $q) => $q->where('status', $status))
            ->latest('id')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function paginateForMember(User $member, int $perPage = 15): LengthAwarePaginator
    {
        return Notice::query()
            ->visibleToMember($member)
            ->latest('publish_at')
            ->latest('id')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findVisibleToMemberOrFail(User $member, int $noticeId): Notice
    {
        return Notice::query()
            ->visibleToMember($member)
            ->whereKey($noticeId)
            ->firstOrFail();
    }

    /**
     * Recipient query for chunked processing (active members only).
     */
    public function recipientQuery(Notice $notice): Builder
    {
        return match ($notice->audience_type) {
            NoticeAudienceType::AllActiveMembers => User::query()
                ->where('role', UserRole::Member)
                ->where('is_active', true)
                ->orderBy('id'),
            NoticeAudienceType::Role => User::query()
                ->where('role', $notice->audience_role ?? UserRole::Member->value)
                ->where('is_active', true)
                ->orderBy('id'),
            NoticeAudienceType::SelectedMembers => User::query()
                ->where('role', UserRole::Member)
                ->where('is_active', true)
                ->whereIn('id', $notice->targets()->select('user_id'))
                ->orderBy('id'),
        };
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function assertAudience(NoticeAudienceType $audience, array $data): void
    {
        if ($audience === NoticeAudienceType::Role) {
            $role = $data['audience_role'] ?? null;
            if (! is_string($role) || UserRole::tryFrom($role) === null) {
                throw new InvalidArgumentException('A valid audience_role is required for role targeting.');
            }
        }

        if ($audience === NoticeAudienceType::SelectedMembers) {
            $ids = $data['member_ids'] ?? [];
            if (! is_array($ids) || $ids === []) {
                throw new InvalidArgumentException('member_ids are required for selected_members audience.');
            }
        }
    }

    /**
     * @param  list<int>  $memberIds
     */
    private function syncTargets(Notice $notice, array $memberIds): void
    {
        $unique = array_values(array_unique(array_map('intval', $memberIds)));

        $validIds = User::query()
            ->where('role', UserRole::Member)
            ->where('is_active', true)
            ->whereIn('id', $unique)
            ->pluck('id')
            ->all();

        if ($validIds === []) {
            throw new InvalidArgumentException('No valid active members selected.');
        }

        $notice->targets()->delete();
        foreach (array_chunk($validIds, 250) as $chunk) {
            $rows = array_map(fn (int $id) => [
                'notice_id' => $notice->id,
                'user_id' => $id,
                'created_at' => now(),
                'updated_at' => now(),
            ], $chunk);
            DB::table('notice_targets')->insert($rows);
        }
    }
}
