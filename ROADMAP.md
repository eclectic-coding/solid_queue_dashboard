# Roadmap

Post-1.0 planned features for [SolidQueueWeb](https://github.com/eclectic-coding/solid_queue_web).

Pull requests for any of these are welcome. See [Contributing](README.md#contributing).

---



## v1.4 — Alerting Depth

*More signals, fewer blind spots.*

| Feature | Notes |
|---|---|
| ~~**Slow job webhook alert**~~ | ✅ Shipped in v1.4 — `alert_slow_job_count_threshold` fires when slow-job count meets or exceeds the threshold. |
| ~~**Process stale webhook alert**~~ | ✅ Shipped in v1.4 — `alert_stale_process_threshold` fires when stale worker count meets or exceeds the threshold. |
| ~~**Job wait time column**~~ | ✅ Shipped in v1.4 — "Wait Time" column on the Running tab; `wait_time_seconds` in the claimed CSV export. |

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
