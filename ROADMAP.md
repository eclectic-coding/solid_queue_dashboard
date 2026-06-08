# Roadmap

Post-1.0 planned features for [SolidQueueWeb](https://github.com/eclectic-coding/solid_queue_web).

Pull requests for any of these are welcome. See [Contributing](README.md#contributing).

---

## v1.6 — Extensibility

*Breaking changes or large architectural additions — planned only if community demand warrants it.*

| Feature | Notes |
|---|---|
| **i18n / locale support** | Wrap all user-visible strings in `I18n.t`. Makes the gem usable for non-English apps. |
| **Custom dashboard cards** | Registration hook so host apps can add their own stat cards alongside queue stats. |
| **Custom nav links** | `config.nav_links = [{ label: "Admin", url: "/admin" }]` to integrate the dashboard into the host app's navigation. |
