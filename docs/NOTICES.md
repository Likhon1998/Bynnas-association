# Notices & Notifications (Stage 6)

## Overview

Association notices are authored by Super Admin / Admin in draft form, previewed for recipient count, then published. Publishing **queues** chunked delivery jobs — the HTTP request never fans out ~3,000 notifications synchronously.

Members only see notices intended for them (`all_active_members`, `selected_members`, or `role`).

## Tables

| Table | Purpose |
|---|---|
| `notices` | Draft / published / archived announcements |
| `notice_targets` | Selected-member audience rows |
| `user_notifications` | In-app inbox with `dedupe_key` for retry safety |
| `device_tokens` | FCM device token registration / invalidation |

## Delivery pipeline

1. `NoticeService::publish` marks notice published and dispatches `PublishNoticeJob`
2. `PublishNoticeJob` uses `chunkById` on recipients and dispatches `DeliverNoticeChunkJob` per chunk
3. `DeliverNoticeChunkJob` creates `user_notifications` with dedupe key `notice:{id}:user:{userId}` and optionally calls `PushNotificationSender`

Other notifications:

- `NotifyPaymentRecordedJob` — after a newly posted payment (`payment:{id}:recorded`)
- `SendDuesReminderJob` via `php artisan notifications:dues-reminders` — monthly / outstanding (`outstanding_dues:{user}:{period}` / `dues_reminder:{user}:{period}`)

## Push (FCM)

`PushNotificationSender` is bound in `AppServiceProvider`:

- Credentials present → `FcmPushNotificationSender` (legacy server key path)
- Otherwise → `NullPushNotificationSender` (logs skip; **no claim of real delivery**)

Environment (never commit secrets):

```env
FCM_SERVER_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_CREDENTIALS=          # optional path to service-account JSON for future HTTP v1
```

Mobile registers tokens via `POST /api/v1/device-tokens` and invalidates via `DELETE /api/v1/device-tokens`.

## Queue

Use `QUEUE_CONNECTION=database` (default in `.env.example`) and run a worker:

```bash
php artisan queue:work
```

PHPUnit uses `sync` so jobs run inline unless `Queue::fake()` is used in a test.
