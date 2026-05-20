# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Queue throughput columns — Done (24h) and Failed (24h) counts per queue on the Queues page; powered by two grouped COUNT queries; Done renders in green, Failed renders in red when non-zero
- Auto-refresh on the Job History page — wraps the page in a turbo-frame polled every 10 seconds, matching the jobs and processes pages; pauses when the browser tab is hidden
- Job History page (`/jobs/history`) — browsable list of all finished jobs (`finished_at IS NOT NULL`) ordered by most-recent-first; columns show class name (links to job detail), queue (clickable queue filter), duration (formatted as `Xs`, `Xm Xs`, or `Xh Xm`), and finished timestamp; filterable by time period (1h / 24h / 7d), queue name, and class name search; paginated; "Done (1h)" and "Done (24h)" dashboard stat cards now link to the history page pre-filtered by period; "History" nav link added between Jobs and Failed
- Throughput section on the dashboard — "Done (1h)" and "Done (24h)" stat cards show completed-job counts; a full-width "Throughput — Last 12 Hours" card displays a pure-CSS bar chart (12 hourly buckets, oldest left → newest right, tick labels every 3 bars) with no JavaScript or charting library; powered by a single `pluck(:finished_at)` query with Ruby-side grouping for DB-agnostic compatibility; seed data updated with a realistic daily-pattern distribution so the chart shows meaningful data out of the box

### Changed

- CSS split into 10 focused partial files (`_01_base.css` through `_10_responsive.css`); `inline_styles` helper globs `_*.css` files in sort order — runtime output is identical, authoring is easier

### Fixed

- Auto-refresh no longer wipes checkbox selections — refresh skips its tick whenever any checkbox inside the turbo-frame is checked and resumes once selections are cleared or submitted

## [0.6.0] - 2026-05-19

### Added

- Job selection and targeted bulk actions — checkboxes on the jobs index (ready/scheduled/blocked) and failed jobs index; a selection bar appears above the table showing the count and action buttons ("Discard Selected" for jobs, "Retry Selected" / "Discard Selected" for failed jobs); select-all checkbox in the table header; powered by a new `selection` Stimulus controller that injects checked IDs into a hidden form on submit; uses nested singular resources (`Jobs::SelectionsController`, `FailedJobs::SelectionsController`) following Rails conventions
- Auto-refresh for dashboard, jobs list, and processes — a `refresh` Stimulus controller polls the current page at a configurable interval (5 s for dashboard, 10 s for jobs/processes) and swaps the matching `<turbo-frame>` content in place; polling pauses when the browser tab is hidden and resumes with an immediate refresh when the tab becomes visible again
- Time-based period filter (`?period=1h|24h|7d`) on the jobs and failed jobs indexes — filters results by enqueued timestamp; period pills render inline with the search bar, right-justified; active period is preserved across status tab switches, search, queue filters, and bulk actions
- Global job search at `/jobs/search` — queries all execution models (ready, scheduled, claimed, blocked, failed) by class name substring; results grouped by status with match count and a "View all →" link; native `<datalist>` autocomplete pre-populated from all known job class names; auto-submits on datalist selection via the `search` Stimulus controller
- `spec/dummy/bin/rails` — enables `bin/rails console` and `bin/rails server` from the dummy app directory during local development

## [0.5.5] - 2026-05-19

### Added

- Failed jobs search: `?q=` param filters by class name substring on the failed jobs index
- Failed jobs queue filter: queue names in the failed jobs table are clickable links that filter to that queue; a "Filtering by queue" indicator appears with a clear link
- Queue-scoped Retry All / Discard All on failed jobs: bulk actions apply only to the active queue/search filter and redirect back preserving those params
- Blocked job detail: job show page displays "Blocked Until" (`BlockedExecution#expires_at`) when the job has a blocked execution
- Queue-scoped jobs view at `/jobs/queues/:queue_name/list` — dedicated `Queues::JobsController` with status tabs, class name search, per-row discard (Turbo Stream), and Discard All scoped to the queue; navigated to by clicking queue names on the global jobs list

### Fixed

- Job detail links inside the turbo frame on the jobs index rendered "Content missing" because the show page has no matching frame; fixed with `data-turbo-frame="_top"` so navigation breaks out to a full page load

### Changed

- `JobsController#index` no longer filters by queue — queue filtering is owned by `Queues::JobsController`
- `JobsController#show` no longer assigns `@failed_execution` / `@blocked_execution`; view reads associations directly from `@job` (already eager-loaded)
- Removed stale `queue: @queue` from status tab links in the jobs index (param was always `nil` after the queue controller refactor)

## [0.5.0] - 2026-05-19

### Added

- Job class name search field on the jobs index — filters the current status tab by class name substring; case-insensitive; persists across status tab switches
- Dynamic search: auto-submits after 4 characters typed or on clear (300 ms debounce) via a Stimulus `search` controller (`app/javascript/solid_queue_web/search_controller.js`)
- Turbo Frame navigation on the jobs index — status filter tabs, search, and pagination update only the table region without a full page reload; URL is pushed to browser history so filtering is bookmarkable
- `importmap-rails` integration: engine registers its own `config/importmap.rb`, adds `app/javascript/` to the asset pipeline, and loads via `javascript_importmap_tags` in the layout
- `@hotwired/turbo` imported in the engine entry point so Turbo is active within the engine's own layout
- Recurring Tasks page (`/jobs/recurring_tasks`) showing key, cron schedule, job class or command, queue, next run time, last run time, and Static/Dynamic badge; eager loads recurring executions to avoid N+1
- Recurring Tasks stat card on the dashboard (cyan, links to the page)
- "View recurring tasks" button in the dashboard Quick Links
- `sqd-badge--static` (green) and `sqd-badge--dynamic` (purple) badge variants
- Hamburger toggle nav for viewports narrower than 576px — three-bar button opens a full-width dropdown with vertically stacked links; no JS file required
- `sqd-grid-2` utility class for responsive two-column layouts (collapses to one column at ≤768px)
- `.sqd-sr-only` utility class for visually-hidden text
- `:focus-visible` focus ring (2px primary blue) for keyboard navigation
- `aria-expanded` on the mobile nav toggle, kept in sync on open/close
- `role="status"` on notice flash messages and `role="alert"` on alert flash messages
- `aria-label="Main"` on the primary navigation landmark
- `aria-current="page"` on the active navigation link
- `scope="col"` on all table header cells
- Visually-hidden "Actions" label on empty action column headers

### Changed

- Dashboard stat card order aligned with nav: Ready, Scheduled, Running, Blocked, Failed, Queues, Recurring, Processes
- Stat grid minimum cell width reduced from 150px to 128px so all 8 cards fit in one row
- Navbar title and links constrained to the same max-width as page content so they align horizontally with the dashboard
- Page headers stack vertically on mobile (≤640px)
- Stat grid uses a smaller minimum cell width on mobile
- Cards scroll horizontally on mobile to accommodate wide tables
- Main content padding reduced on mobile

## [0.4.0] - 2026-05-18

### Added

- Turbo Streams on the jobs list — discarding a single job removes its row in place; the last job swaps the card to an empty state without a full page reload
- Turbo Frame on the jobs list — status filter tabs, queue filter links, Discard All button, and pagination all update in place without reloading the page header or flash
- Dashboard stat cards are now clickable links to their respective filtered views
- GitHub Releases created automatically with CHANGELOG notes when a version tag is pushed
- `turbo-rails >= 2.0` added as a runtime dependency

### Changed

- `JobsController` refactored: execution model mapping moved to `EXECUTION_MODELS` hash constant, eliminating two `case` statements
- `JobsController#destroy` and `#discard_all` share a `before_action :set_status_and_queue` and a `filtered_scope` helper, removing duplicated param reading and scope building

### Fixed

- Test suite reaches 100% line coverage; rescue paths, `derive_status` branches (scheduled, finished), and the authentication block are all exercised

## [0.3.0] - 2026-05-18

### Added

- Processes page showing workers, dispatchers, and supervisors with kind, PID, host, metadata, last heartbeat, and Healthy/Stale status
- Queue pause / resume — Pause and Resume buttons per row on the Queues page
- Pagination for jobs and failed jobs lists via pagy (25 per page)
- Jobs URL segment renamed from `/jobs/jobs` to `/jobs/list`
- Job detail page showing status, queue, priority, arguments (pretty-printed JSON), and full error backtrace for failed jobs
- Retry/Discard action buttons on the detail page based on job status
- Job class names on the jobs and failed jobs index pages link to the detail page
- Retry and discard actions on individual failed jobs
- Bulk "Retry All" and "Discard All" actions for failed jobs
- Discard action on individual ready, scheduled, and blocked jobs
- Bulk "Discard All" action for ready, scheduled, and blocked jobs (scoped to current queue filter)
- Roadmap section added to README with planned features and contribution guidelines

### Fixed

- Failed jobs view now renders error class and message correctly (seed data format and missing CSS class)

## [0.2.0] - 2026-05-18

### Added

- CI release job publishes gem to RubyGems automatically on version tags
- Trusted Publishing via OIDC — no stored API keys required

### Fixed

- CSS is now inlined in the layout via a helper — no asset pipeline (Sprockets/Propshaft) required in the host app
- Renamed gem from `solid_queue_dashboard` to `solid_queue_web` to avoid conflict with an existing RubyGems package

## [0.1.0] - 2026-05-18

### Added

- Rails engine scaffold with isolated namespace `SolidQueueWeb`
- Configurable authentication hook (`SolidQueueWeb.authenticate`)
- Read-only dashboard with stat cards for ready, scheduled, running, blocked, and failed jobs
- Queues index page showing all queues sorted by name
- Jobs index with status filter tabs (ready, scheduled, claimed, blocked, failed) and per-queue filtering
- Failed jobs index page
- Minimal inline CSS with stat cards, tables, and status badges — no external CSS framework required
- Runtime dependencies: `rails >= 8.1.3`, `solid_queue >= 1.0`
- RSpec test suite with dummy Rails app for engine request specs
- SimpleCov code coverage reporting
- RuboCop linting via `rubocop-rails-omakase`; `bundle exec rake` runs the full suite
- CI workflow with lint (RuboCop) and test (RSpec) matrix across Ruby 3.3, 3.4, and 4.0
- `bin/release` script for versioned gem releases

[Unreleased]: https://github.com/eclectic-coding/solid_queue_web/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.6.0
[0.5.5]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.5.5
[0.5.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.5.0
[0.4.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.1.0
