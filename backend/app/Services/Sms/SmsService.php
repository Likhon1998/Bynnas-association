<?php

namespace App\Services\Sms;

use App\Contracts\SmsGateway;
use App\Enums\NoticeAudienceType;
use App\Enums\UserRole;
use App\Models\SmsDelivery;
use App\Models\SmsMessage;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class SmsService
{
    public function __construct(
        private readonly SmsGateway $gateway,
    ) {}

    /**
     * @param  array{
     *     body: string,
     *     audience_type?: string,
     *     member_ids?: list<int>|null,
     * }  $data
     */
    public function sendBroadcast(User $actor, array $data): SmsMessage
    {
        $audience = $data['audience_type'] ?? NoticeAudienceType::AllActiveMembers->value;
        $recipients = $this->resolveRecipients($audience, $data['member_ids'] ?? null);

        return DB::transaction(function () use ($actor, $data, $audience, $recipients) {
            $message = SmsMessage::query()->create([
                'created_by' => $actor->id,
                'body' => $data['body'],
                'audience_type' => $audience,
                'recipient_count' => $recipients->count(),
                'status' => 'sending',
            ]);

            $sent = 0;
            $failed = 0;

            foreach ($recipients as $member) {
                $phone = $member->memberProfile?->phone;
                if (! filled($phone)) {
                    SmsDelivery::query()->create([
                        'sms_message_id' => $message->id,
                        'user_id' => $member->id,
                        'phone' => '',
                        'status' => 'failed',
                        'error_message' => 'No phone on file',
                    ]);
                    $failed++;

                    continue;
                }

                $result = $this->gateway->send($phone, $data['body']);
                SmsDelivery::query()->create([
                    'sms_message_id' => $message->id,
                    'user_id' => $member->id,
                    'phone' => $phone,
                    'status' => $result['success'] ? 'sent' : 'failed',
                    'provider_message_id' => $result['provider_message_id'],
                    'error_message' => $result['error'],
                    'sent_at' => $result['success'] ? now() : null,
                ]);
                $result['success'] ? $sent++ : $failed++;
            }

            $message->forceFill([
                'status' => $failed === 0 ? 'completed' : ($sent === 0 ? 'failed' : 'partial'),
            ])->save();

            return $message->load(['deliveries', 'creator']);
        });
    }

    /**
     * @param  list<int>|null  $memberIds
     * @return Collection<int, User>
     */
    private function resolveRecipients(string $audience, ?array $memberIds): Collection
    {
        $query = User::query()
            ->with('memberProfile')
            ->where('role', UserRole::Member)
            ->where('is_active', true);

        if ($audience === NoticeAudienceType::SelectedMembers->value) {
            $query->whereIn('id', $memberIds ?? []);
        }

        return $query->get();
    }
}
