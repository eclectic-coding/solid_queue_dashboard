# Roadmap

Post-1.0 planned features for [SolidQueueWeb](https://github.com/eclectic-coding/solid_queue_web).

Pull requests for any of these are welcome. See [Contributing](README.md#contributing).

---


## v1.3 — UX Polish

*Quality-of-life improvements for teams using the dashboard daily.*

| Feature | Notes |
|---|---|
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
