# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- RSpec test environment with dummy Rails app for request specs
- SimpleCov code coverage reporting with Rails profile and grouped output
- RuboCop and RSpec rake tasks; `bundle exec rake` runs the full suite
- CI test job running `bundle exec rspec`

## [0.1.0] - 2026-05-18

### Added

- Rails engine scaffold with isolated namespace `SolidQueueDashboard`
- Configurable authentication hook (`SolidQueueDashboard.authenticate`)
- Dashboard page with stat cards for ready, scheduled, running, blocked, failed jobs, queues, and processes
- Queues page with pause/resume actions and latency display
- Jobs page with status filter tabs (ready, scheduled, running, blocked, failed) and per-queue filtering
- Failed jobs page with per-job retry and discard, and bulk discard-all
- Pagination via pagy (v43+)
- Minimal CSS with stat cards, tables, badges, and buttons — no external CSS framework required
- Runtime dependencies: `rails >= 8.1.3`, `solid_queue >= 1.0`, `pagy >= 9.0`
- CI workflow with lint (RuboCop) and test (RSpec) jobs

[Unreleased]: https://github.com/eclectic-coding/solid_queue_dashboard/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/eclectic-coding/solid_queue_dashboard/releases/tag/v0.1.0