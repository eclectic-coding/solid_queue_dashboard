# SolidQueueWeb

[![CI](https://github.com/eclectic-coding/solid_queue_web/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/solid_queue_web/actions/workflows/ci.yml)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.3-CC342D)](https://rubygems.org/gems/solid_queue_web)
[![Gem Version](https://img.shields.io/gem/v/solid_queue_web)](https://rubygems.org/gems/solid_queue_web)
[![Downloads](https://img.shields.io/gem/dt/solid_queue_web)](https://rubygems.org/gems/solid_queue_web)
[![Coverage](https://codecov.io/gh/eclectic-coding/solid_queue_web/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/solid_queue_web)

A monitoring and management dashboard for [Solid Queue](https://github.com/rails/solid_queue), mountable as a Rails engine in any app.

> **Note:** Development of this gem will continue, but if you need a unified dashboard that covers **Solid Queue**, **Solid Cable**, and **Solid Cache** in a single interface, check out [solid_stack_web](https://github.com/eclectic-coding/solid_stack_web).

![SolidQueueWeb dashboard](docs/solid-queue-web.png)

## Table of Contents

- [The problem](#the-problem)
- [Why SolidQueueWeb?](#why-solidqueueweb)
- [Real-world use case](#real-world-use-case)
- [Features](#features)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Mounting the engine](#mounting-the-engine)
- [Configuration](#configuration)
- [Webhook alerts](#webhook-alerts)
  - [Failure threshold alerts](#failure-threshold-alerts)
  - [Queue depth alerts](#queue-depth-alerts)
  - [Slow job alerts](#slow-job-alerts)
  - [Stale process alerts](#stale-process-alerts)
- [Admin audit log](#admin-audit-log)
  - [Setup](#setup)
  - [Identity](#identity)
  - [Audited actions](#audited-actions)
- [Metrics endpoint](#metrics-endpoint)
- [Read replica support](#read-replica-support)
- [i18n](#i18n)
  - [Adding a custom locale](#adding-a-custom-locale)
- [Extensibility](#extensibility)
  - [Custom dashboard cards](#custom-dashboard-cards)
  - [Custom nav links](#custom-nav-links)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## The problem

Solid Queue ships without a web interface. When jobs fail, queues back up, or workers go silent in production, the only options are `rails console` or raw SQL queries. SolidQueueWeb gives your team a real-time dashboard to inspect, retry, and discard jobs without leaving the browser — and without standing up any additional infrastructure.

[↑ Back to top](#table-of-contents)

---

## Why SolidQueueWeb?

- Purpose-built for Solid Queue — uses its native models directly, no adapters
- No external CSS framework — drops into any Rails app without asset conflicts
- Zero-config to start — one line in `routes.rb` and you're running
- Built for Rails 8 — Turbo Frames for in-place updates, Stimulus for dynamic search and auto-refresh, Pagy for efficient pagination
- Inspired by Sidekiq Web UI and the GoodJob dashboard, adapted for the Solid Queue ecosystem

[↑ Back to top](#table-of-contents)

---

## Real-world use case

A Rails app processes order confirmations, email notifications, and report generation through Solid Queue. An operations team needs to:

- Monitor queue depth before a high-traffic event
- Retry a batch of failed notification jobs after a third-party API outage
- Pause a queue while a fix is being deployed
- Identify blocked or long-running jobs before they impact users

SolidQueueWeb surfaces all of this in a browser UI available at any route you choose.

[↑ Back to top](#table-of-contents)

---

## Features

- **Dashboard** — stat cards showing counts for ready, scheduled, running, blocked, and failed jobs, plus queues, recurring tasks, and processes; "Done (1h)" and "Done (24h)" throughput cards; a "Throughput — Last 12 Hours" bar chart (blue) and a "Queue Depth — Last 12 Hours" bar chart (purple) showing hourly snapshots of active job count; pure CSS, no charting library; auto-refreshes every 5 seconds
- **Queues** — all queues sorted by name with size; oldest ready job latency (color-coded, with UTC timestamp tooltip); Done (24h) and Failed (24h) throughput counts; a mini 12-bar failure rate sparkline per queue showing failure % per hour over the last 12 hours; pause/resume controls
- **Jobs** — filterable by status (ready, scheduled, claimed, blocked, failed), queue, and priority; search by job class name with dynamic auto-submit; time-based period filter (1 h / 24 h / 7 d); sortable by class, queue, priority, and enqueued-at; sort state is preserved across filter, period, and status tab changes; discard individual or all jobs; Turbo Frame navigation so only the table updates on filter or search; auto-refreshes every 10 seconds
- **Scheduled job management** — reschedule a scheduled job to run immediately ("Run Now") or push its `scheduled_at` forward by 1 h, 24 h, or 7 d; Turbo Stream responses update the row in place; "Run All Now" bulk action promotes every scheduled job in the current filtered view in a single operation
- **Failed jobs** — list of failed executions with error details; search by class name; filter by queue; time-based period filter; sortable by class, queue, and failed-at; retry or discard individually or in bulk; bulk retry with configurable stagger (+5s / +10s / +30s / +1m) to avoid thundering herd on recovery
- **Job detail** — full arguments, timestamps, blocked-until date, and error backtrace; action buttons based on job status; failed jobs show an editable arguments textarea so you can correct a bad payload and retry in one step without redeploying
- **Queue management** — pause and resume individual queues; queue-scoped job list with status filter, search, and discard
- **Recurring tasks** — all configured recurring tasks with cron schedule, next run time, last run time, and static/dynamic classification; "Run Now" button enqueues a task immediately without waiting for its next scheduled run
- **Processes** — workers, dispatchers, and supervisors with heartbeat health status; auto-refreshes every 10 seconds
- **Global search** — search across all job statuses at once by class name substring; results grouped by status with match count and direct links to filtered views; native datalist autocomplete pre-populated from all known job classes; auto-submits on selection
- **Targeted bulk actions** — checkboxes on the jobs and failed jobs lists for selecting individual rows; selection bar shows count and action buttons ("Discard Selected" for jobs, "Retry Selected" / "Discard Selected" for failed jobs); select-all checkbox in the table header
- **Job history** — browsable list of all finished jobs with class name, queue, duration, and finished timestamp; filterable by period (1h / 24h / 7d), queue, and class name search; sortable by class, queue, and finished-at; Done (1h) / Done (24h) dashboard cards link directly to the filtered history view; auto-refreshes every 10 seconds
- **Dark mode** — ☽/☀ toggle in the header; preference persists to `localStorage` and defaults to the OS `prefers-color-scheme` on first visit; zero extra dependencies — implemented via CSS custom properties and a small Stimulus controller
- **Dashboard quick actions** — "Retry All Failed" and "Discard All Blocked" cards appear on the dashboard only when the respective count is non-zero; one-click bulk operations with confirm dialogs, keeping the dashboard clean when everything is healthy
- **CSV export** — "Export CSV" button on the jobs, failed jobs, and history pages downloads all records matching the current filters; columns are tailored per view
- **Slow job detection** — when `slow_job_threshold` is configured, claimed jobs running longer than the threshold are flagged with an orange row, a "slow" badge, and a "Running For" duration column on the Running tab; a "Slow Jobs" warning card appears on the dashboard with a link to the Running tab
- **Job wait time** — the Running tab shows a "Wait Time" column with how long each job waited in the queue from enqueue to pickup; also exported as `wait_time_seconds` in the claimed-status CSV
- **Admin audit log** — every discard, retry, queue pause, and resume is recorded to a `solid_queue_web_audit_events` table and viewable at `/jobs/audit` with action/actor/queue filters and CSV export; actor identity captured via the optional `current_actor` config block; requires running the install generator to create the table
- **Webhook alerts** — set `alert_webhook_url` and `alert_failure_threshold` to receive a POST request whenever the failed job count meets or exceeds the threshold; set `alert_queue_thresholds` for per-queue depth alerts; set `alert_slow_job_count_threshold` (requires `slow_job_threshold`) for slow-job count alerts; set `alert_stale_process_threshold` for stale-worker alerts; all fire asynchronously with a configurable cooldown (default 1 h) to prevent repeated alerts
- **Performance analytics** — per-job-class statistics at `/jobs/performance` showing run count, average, p50, p95, p99, standard deviation, min, and max duration; sorted by p95 descending so the slowest classes surface first; high std dev surfaces inconsistent jobs worth investigating; period filter scopes to 1h / 24h / 7d or all time; each class name links to the filtered History view
- **Failed job trend chart** — a "Failures — Last 12 Hours" bar chart on the dashboard shows failures per hour over the last 12 hours; bars are red, making failure spikes visible before clicking into the failed jobs list
- **Error frequency report** — `GET /jobs/failed_jobs/errors` groups all failed jobs by error class and message prefix, shows a count per group, and surfaces a sample backtrace in an expandable row; sorted by count descending so the most common errors appear first; accessible via the "Error Summary" button on the Failed Jobs page
- **Metrics / health endpoint** — `GET /jobs/metrics.json` returns a machine-readable JSON document with job counts, throughput, per-queue depth and pause state, and process health summary; suitable for Prometheus scraping, uptime monitors, or external dashboards; `slow_jobs` count included when `slow_job_threshold` is configured
- **i18n** — all UI strings (page titles, table headers, buttons, empty states, flash messages) are backed by `config/locales/en.yml`; locale switching via `?locale=` param or session; add a custom locale by supplying a YAML file in your host app and registering it with `config.available_locales`
- **Custom dashboard cards** — `config.dashboard_cards` accepts an array of `{ title:, stats:, link: }` hashes rendered after the built-in queue stat cards; `stats:` is a lambda returning a `{ label => value }` hash evaluated at render time; `link:` is an optional header link
- **Custom nav links** — `config.nav_links` accepts an array of `{ label:, url: }` hashes appended to the main navigation bar after the built-in links

[↑ Back to top](#table-of-contents)

---

## Compatibility

| Dependency  | Version    |
|-------------|------------|
| Ruby        | >= 3.3     |
| Rails       | >= 8.1.3   |
| Solid Queue | >= 1.0     |

Tested on Ruby 3.3, 3.4, and 4.0.

[↑ Back to top](#table-of-contents)

---

## Installation

Add to your application's Gemfile:

```ruby
gem "solid_queue_web"
```

Then run:

```bash
bundle install
```

[↑ Back to top](#table-of-contents)

---

## Mounting the engine

Add to your `config/routes.rb`:

```ruby
mount SolidQueueWeb::Engine, at: "/jobs"
```

The dashboard will be available at `/jobs`.

[↑ Back to top](#table-of-contents)

---

## Configuration

All settings are optional — the dashboard works with zero configuration. Create `config/initializers/solid_queue_web.rb` to customize behavior:

```ruby
SolidQueueWeb.configure do |config|
  config.page_size                  = 50     # rows per page across all paginated views (default: 25)
  config.dashboard_refresh_interval = 10_000 # dashboard auto-refresh in ms (default: 5_000)
  config.default_refresh_interval   = 30_000 # jobs/processes/history auto-refresh in ms (default: 10_000)
  config.search_results_limit       = 10     # max results per status in global search (default: 25)
  config.slow_job_threshold         = 5.minutes # flag claimed jobs running longer than this (default: nil = disabled)
  config.alert_webhook_url          = "https://hooks.example.com/solid-queue" # POST target — string or array (default: nil = disabled)
  config.alert_failure_threshold    = 10         # fire when failed count >= this (default: nil = disabled)
  config.alert_queue_thresholds          = { "critical" => 50, "default" => 200 } # fire when queue depth >= threshold (default: {})
  config.alert_slow_job_count_threshold  = 5          # fire when slow job count >= this (default: nil = disabled)
  config.alert_stale_process_threshold  = 1          # fire when stale process count >= this (default: nil = disabled)
  config.alert_webhook_cooldown         = 1800       # seconds between repeated alerts per alert type (default: 3600)
  config.current_actor                  = -> { current_user&.email } # identity for audit log (default: nil)
  config.connects_to                = { reading: :reading, writing: :writing } # read replica (default: nil)
  config.time_zone                  = "America/New_York" # display timezone for all timestamps (default: nil = UTC)
  config.available_locales          = [:en, :fr]         # locales available for switching (default: [:en])
  config.nav_links                  = [{ label: "Admin", url: "/admin" }] # extra nav links (default: [])
  config.dashboard_cards            = [{ title: "My App", stats: -> { { "Users" => User.count } } }] # custom stat cards (default: [])
end

SolidQueueWeb.authenticate do
  # Called in the context of ApplicationController — use any helper available there.
  # Return a truthy value to allow access, falsy to deny (triggers HTTP Basic prompt).
  current_user&.admin?
end
```

No authentication is enforced by default. When the `authenticate` block returns falsy, HTTP Basic auth is used as a fallback.

[↑ Back to top](#table-of-contents)

---

## Webhook alerts

The engine supports four webhook alert types, each firing asynchronously with a configurable cooldown to prevent repeated alerts.

### Failure threshold alerts

Set `alert_webhook_url` and `alert_failure_threshold` to receive a POST request whenever the failed job count meets or exceeds the threshold. This is useful for paging an on-call team or triggering a Slack notification via an incoming webhook.

```ruby
SolidQueueWeb.configure do |config|
  config.alert_webhook_url       = "https://hooks.slack.com/services/..."
  config.alert_failure_threshold = 10    # fire when >= 10 jobs have failed
  config.alert_webhook_cooldown  = 1800  # don't re-fire for 30 minutes (default: 3600)
end
```

To fan out to multiple endpoints (e.g. Slack and PagerDuty simultaneously), pass an array:

```ruby
config.alert_webhook_url = [
  "https://hooks.slack.com/services/...",
  "https://events.pagerduty.com/..."
]
```

All configured URLs receive the same payload. A failure posting to one URL is logged and skipped without blocking the remaining targets.

The request body is JSON:

```json
{
  "event": "failure_threshold_exceeded",
  "failure_count": 14,
  "threshold": 10,
  "fired_at": "2026-05-21T12:34:56Z"
}
```

The webhook fires asynchronously in a background thread so dashboard page loads are never delayed. HTTP errors are logged to `Rails.logger` and swallowed. The cooldown window prevents repeated alerts while the count stays elevated — the clock resets on each app restart.

### Queue depth alerts

Set `alert_queue_thresholds` to fire a webhook when any queue's ready job count meets or exceeds a per-queue limit:

```ruby
SolidQueueWeb.configure do |config|
  config.alert_webhook_url      = "https://hooks.example.com/solid-queue"
  config.alert_queue_thresholds = { "critical" => 50, "default" => 200 }
end
```

The same `alert_webhook_url` endpoint(s) receive the payload, with a distinct event type so you can route it differently:

```json
{
  "event": "queue_depth_threshold_exceeded",
  "queue_name": "critical",
  "depth": 63,
  "threshold": 50,
  "fired_at": "2026-05-21T12:34:56Z"
}
```

Cooldown is tracked independently per queue, so a persistently deep "critical" queue does not suppress alerts for "default". The shared `alert_webhook_cooldown` setting applies to each queue separately.

### Slow job alerts

Set `alert_slow_job_count_threshold` to fire a webhook when the number of currently-running slow jobs meets or exceeds a count. This requires `slow_job_threshold` to also be configured — it defines what "slow" means.

```ruby
SolidQueueWeb.configure do |config|
  config.slow_job_threshold             = 5.minutes  # a job is "slow" if it has been claimed longer than this
  config.alert_slow_job_count_threshold = 3           # fire when >= 3 jobs are slow
  config.alert_webhook_url              = "https://hooks.example.com/solid-queue"
  config.alert_webhook_cooldown         = 1800        # don't re-fire for 30 minutes (default: 3600)
end
```

The same `alert_webhook_url` endpoint(s) receive the payload with a distinct event type:

```json
{
  "event": "slow_job_threshold_exceeded",
  "slow_job_count": 5,
  "threshold": 3,
  "fired_at": "2026-05-28T08:00:00Z"
}
```

The alert fires on every dashboard page load while the condition persists, subject to the cooldown window.

### Stale process alerts

Set `alert_stale_process_threshold` to fire a webhook when the number of stale workers meets or exceeds a count. A process is considered stale when its `last_heartbeat_at` has not been updated within `SolidQueue.process_alive_threshold` (default 5 minutes). A stale worker means jobs in its queues have silently stopped processing.

```ruby
SolidQueueWeb.configure do |config|
  config.alert_stale_process_threshold = 1    # fire when any process goes stale
  config.alert_webhook_url             = "https://hooks.example.com/solid-queue"
  config.alert_webhook_cooldown        = 1800  # don't re-fire for 30 minutes (default: 3600)
end
```

The same `alert_webhook_url` endpoint(s) receive the payload with a distinct event type:

```json
{
  "event": "stale_process_detected",
  "stale_process_count": 2,
  "threshold": 1,
  "fired_at": "2026-05-28T08:00:00Z"
}
```

The alert fires on every dashboard page load while the condition persists, subject to the cooldown window.

[↑ Back to top](#table-of-contents)

---

## Admin audit log

Every discard, retry, queue pause, and resume action is recorded to a `solid_queue_web_audit_events` table and viewable at `/jobs/audit`.

### Setup

The audit log requires an opt-in migration. Run the install generator to copy it to your application:

```bash
rails generate solid_queue_web:install:migrations
rails db:migrate
```

### Identity

Set `SolidQueueWeb.current_actor` to a block that returns the current user's identity as a string. The block is evaluated in controller context, so you have access to helpers like `current_user`:

```ruby
SolidQueueWeb.configure do |config|
  config.current_actor = -> { current_user&.email }
end
```

If not configured, the actor column is left `nil`.

### Audited actions

| Action | Trigger |
|---|---|
| `job_discarded` | Single job discarded from the jobs list |
| `jobs_discarded` | Bulk or selection discard from the jobs list |
| `failed_job_retried` | Single failed job retried |
| `failed_jobs_retried` | Bulk or selection retry of failed jobs |
| `failed_job_discarded` | Single failed job discarded |
| `failed_jobs_discarded` | Bulk or selection discard of failed jobs |
| `queue_paused` | Queue paused |
| `queue_resumed` | Queue resumed |

The audit log page at `/jobs/audit` supports filtering by action, actor, and queue name. All records can be exported as CSV.

[↑ Back to top](#table-of-contents)

---

## Metrics endpoint

`GET /jobs/metrics.json` returns a machine-readable JSON document suitable for Prometheus scraping, uptime monitors, or external dashboards. No configuration is required — the endpoint is available as soon as the engine is mounted.

```
GET /jobs/metrics.json
```

Example response:

```json
{
  "generated_at": "2026-05-21T12:00:00Z",
  "jobs": {
    "ready": 12,
    "scheduled": 8,
    "claimed": 3,
    "blocked": 5,
    "failed": 9
  },
  "throughput": {
    "completed_1h": 15,
    "completed_24h": 87
  },
  "queues": [
    { "name": "critical", "depth": 2, "paused": false },
    { "name": "default",  "depth": 4, "paused": false },
    { "name": "mailers",  "depth": 3, "paused": true  }
  ],
  "processes": {
    "total": 4,
    "healthy": 4,
    "stale": 0,
    "by_kind": { "Dispatcher": 1, "Supervisor": 1, "Worker": 2 }
  }
}
```

When `slow_job_threshold` is configured, a `slow_jobs` integer is also included at the top level.

The endpoint respects the same authentication and `connects_to` settings as the rest of the dashboard. A process is counted as **stale** when its `last_heartbeat_at` is older than `SolidQueue.process_alive_threshold` (default: 5 minutes).

[↑ Back to top](#table-of-contents)

---

## Read replica support

Set `connects_to` with both `reading:` and `writing:` keys to enable automatic role switching. GET requests are routed to the reading role; POST/DELETE/PATCH requests use the writing role.

```ruby
SolidQueueWeb.configure do |config|
  # Route dashboard reads to the replica, writes to primary:
  config.connects_to = { reading: :reading, writing: :writing }
end
```

The role names must match what Solid Queue's models are configured with (set via `SolidQueue.connects_to` in your app). To pin all requests to a single role instead (e.g. to bypass automatic read/write splitting middleware), pass a plain `role:` or `shard:` hash:

```ruby
config.connects_to = { role: :writing }
```

When `connects_to` is `nil` (the default), no connection switching occurs and single-database apps are unaffected.

[↑ Back to top](#table-of-contents)

---

## i18n

All dashboard UI strings — page titles, table headers, button labels, empty states, and flash messages — are backed by `config/locales/en.yml` in the gem. The engine ships with **English (`en`)** only.

The selected locale is stored in the session and applied via `I18n.with_locale`, so it persists across requests without touching the host application's locale. The `?locale=` query param takes precedence over the session value, making it easy to deep-link to a specific language.

```ruby
SolidQueueWeb.configure do |config|
  # Locales available for switching (default: [:en]).
  config.available_locales = [:en, :fr]
end
```

### Adding a custom locale

1. Create a locale file in your host application under `config/locales/`, e.g. `config/locales/solid_queue_web.fr.yml`.
2. Nest all keys under `fr > solid_queue_web:` — use [`config/locales/en.yml`](config/locales/en.yml) in the gem as a reference for the full key list.
3. Register the locale:

```ruby
config.available_locales = [:en, :fr]
```

Rails will pick up the file automatically via its standard `config.i18n.load_path`; no additional configuration is needed.

[↑ Back to top](#table-of-contents)

---

## Extensibility

### Custom dashboard cards

`config.dashboard_cards` adds custom stat cards to the dashboard after the built-in queue cards. Each card accepts three keys:

| Key | Type | Description |
|-----|------|-------------|
| `title` | String | Card heading (required) |
| `link` | `{ label:, url: }` | Optional header link rendered top-right |
| `stats` | Lambda | Optional — called at render time; must return a `{ label => value }` hash |

```ruby
SolidQueueWeb.configure do |config|
  config.dashboard_cards = [
    {
      title: "My App",
      link:  { label: "View Admin", url: "/admin" },
      stats: -> { { "Users" => User.count, "Premium" => User.premium.count } }
    }
  ]
end
```

The `stats` lambda runs on every dashboard render, so keep it fast. Defaults to `[]` — no custom cards appear when unconfigured.

### Custom nav links

`config.nav_links` appends extra links to the main navigation bar after the built-in links. Use it to link back to your host application's admin pages or related tools.

```ruby
SolidQueueWeb.configure do |config|
  config.nav_links = [
    { label: "Back to App", url: "/" },
    { label: "Admin",       url: "/admin" }
  ]
end
```

Defaults to `[]` — no extra links appear when unconfigured.

[↑ Back to top](#table-of-contents)

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full post-1.0 feature plan, organized by release milestone.

Pull requests for any of these are welcome. See [Contributing](#contributing) below.

[↑ Back to top](#table-of-contents)

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/eclectic-coding/solid_queue_web).

[↑ Back to top](#table-of-contents)

---

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[↑ Back to top](#table-of-contents)
