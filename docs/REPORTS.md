# Dashboards & Reports

## Principles

1. **Server-owned totals** — `ReportService` computes expected dues, collections, allocations, and outstanding balances with BCMath/`DECIMAL` sums. UI/API clients display those values; they do not aggregate money client-side.
2. **Role-specific views**
   - Super Admin / Admin: association overview + membership + full reports
   - Accountant: collections & outstanding focus + full financial reports
   - Member (API): self-scoped dashboard only
3. **Filters** — optional `from` / `to` dates; dues filtered by period dates, payments by `received_at`.
4. **Pagination** — report row lists are paginated; the `summary` object always reflects the **entire filtered set**.
5. **Print / PDF** — print-friendly HTML (`?print=1` on web) and DomPDF downloads. Exports reuse the same summary/row builders as interactive reports.
6. **Authorization** — `FinancePolicy::viewDashboard`, `viewReports`, `exportReports`; web routes behind `staff` middleware.

## Metrics

| Metric | Definition |
|---|---|
| Active members | `users` with role member and `is_active` |
| Expected dues | Sum of non-voided `member_dues.amount_due` in filter |
| Actual collections | Sum of `payments.amount` with status `posted` in filter |
| Allocated to dues | Sum of non-voided `member_dues.amount_allocated` in filter |
| Outstanding | Expected − allocated |
| Payment status | Counts of dues by status (`pending` / `partial` / `paid` / `voided`) |

Reversed payments are excluded from collections; their allocations no longer count toward allocated/outstanding after reversal.
