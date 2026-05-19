# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/eclectic-coding/solid_queue_web/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.5.0
[0.4.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.1.0
