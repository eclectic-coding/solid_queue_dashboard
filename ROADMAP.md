# Roadmap

Post-1.0 planned features for [SolidQueueWeb](https://github.com/eclectic-coding/solid_queue_web).

Pull requests for any of these are welcome. See [Contributing](README.md#contributing).

---




## v1.5 — Audit & Compliance

*Requires an opt-in migration — kept separate from the no-migration-required releases above.*

| Feature | Notes |
|---|---|
| ~~**Admin audit log**~~ | ✅ Shipped in v1.5 — `solid_queue_web_audit_events` table via `rails generate solid_queue_web:install:migrations`; `/jobs/audit` page with action/actor/queue filters and CSV export; identity from the `current_actor` config block. |

---

## v2.0 — Extensibility

*Breaking changes or large architectural additions — planned only if community demand warrants it.*

| Feature | Notes |
|---|---|
| **i18n / locale support** | Wrap all user-visible strings in `I18n.t`. Makes the gem usable for non-English apps. |
| **Custom dashboard cards** | Registration hook so host apps can add their own stat cards alongside queue stats. |
| **Custom nav links** | `config.nav_links = [{ label: "Admin", url: "/admin" }]` to integrate the dashboard into the host app's navigation. |
