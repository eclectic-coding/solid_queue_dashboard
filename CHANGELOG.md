# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/eclectic-coding/solid_queue_web/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/solid_queue_web/releases/tag/v0.1.0