# Roadmap

Post-1.0 planned features for [SolidQueueWeb](https://github.com/eclectic-coding/solid_queue_web).

Pull requests for any of these are welcome. See [Contributing](README.md#contributing).

---

## v1.1 — Operations Completeness

*Close the gaps users hit within the first week of real use.*

| Feature | Notes |
|---|---|
| **Retry failed job with modified arguments** | Form on the job detail page — edit the arguments JSON before retrying. Fixes bad payloads without redeploying. |
| **Multiple webhook targets** | Change `alert_webhook_url` to accept an array. Fan out to Slack + PagerDuty simultaneously. |
| **Queue depth alert** | Fire a webhook when a queue's ready count exceeds a per-queue threshold (e.g. `alert_queue_thresholds: { critical: 50 }`). |

---

## v1.2 — Error Intelligence

*Surface patterns in failures, not just individual failed jobs.*

| Feature | Notes |
|---|---|
| **Error frequency report** | Group all failed jobs by error class + message prefix, show count and a sample backtrace. When you have hundreds of failed jobs, you want to see "ArgumentError (x212), TimeoutError (x88)" at a glance. |
| **Failed job trend chart** | A "Failures — Last 12 Hours" sparkline on the dashboard (same pattern as the existing throughput and queue depth charts). Makes failure spikes visible before you click into the failed jobs list. |
| **P99 + std dev in performance analytics** | Extend `JobPerformanceStats` with a 99th percentile and standard deviation column. High std dev signals inconsistent jobs worth investigating. |

---

## v1.3 — UX Polish

*Quality-of-life improvements for teams using the dashboard daily.*

| Feature | Notes |
|---|---|
| **Sortable table columns** | Server-side `?sort=class_name&dir=asc` on jobs, failed jobs, and history. |
| **Configurable display timezone** | `config.time_zone = "America/New_York"` — all timestamps rendered in the configured zone rather than UTC. |
| **Sticky filter preferences** | Persist last-used status/period to `localStorage` so filters survive page reloads. |

---

## v1.4 — Alerting Depth

*More signals, fewer blind spots.*

| Feature | Notes |
|---|---|
| **Slow job webhook alert** | Fire when the slow-jobs count crosses a threshold. Pairs with the existing `slow_job_threshold` config — adds the alerting half. |
| **Process stale webhook alert** | Fire when a worker's `last_heartbeat_at` expires. A worker going silent means jobs stop processing silently. |
| **Job wait time column** | Show time from `enqueued_at` to `created_at` on claimed executions — a direct measure of queue SLA. |

---

## v1.5 — Audit & Compliance

*Requires an opt-in migration — kept separate from the no-migration-required releases above.*

| Feature | Notes |
|---|---|
| **Admin audit log** | Record who retried, discarded, or paused what and when. Needs a `solid_queue_web_audit_events` table via an engine-provided migration (`rails solid_queue_web:install:migrations`). Identity comes from the `authenticate` block. CSV export included. |

---

## v2.0 — Extensibility

*Breaking changes or large architectural additions — planned only if community demand warrants it.*

| Feature | Notes |
|---|---|
| **i18n / locale support** | Wrap all user-visible strings in `I18n.t`. Makes the gem usable for non-English apps. |
| **Custom dashboard cards** | Registration hook so host apps can add their own stat cards alongside queue stats. |
| **Custom nav links** | `config.nav_links = [{ label: "Admin", url: "/admin" }]` to integrate the dashboard into the host app's navigation. |
