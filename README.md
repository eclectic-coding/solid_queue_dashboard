# SolidQueueWeb

[![CI](https://github.com/eclectic-coding/solid_queue_web/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/solid_queue_web/actions/workflows/ci.yml)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.3-CC342D)](https://rubygems.org/gems/solid_queue_web)
[![Gem Version](https://img.shields.io/gem/v/solid_queue_web)](https://rubygems.org/gems/solid_queue_web)
[![Downloads](https://img.shields.io/gem/dt/solid_queue_web)](https://rubygems.org/gems/solid_queue_web)
[![Coverage](https://codecov.io/gh/eclectic-coding/solid_queue_web/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/solid_queue_web)

A monitoring and management dashboard for [Solid Queue](https://github.com/rails/solid_queue), mountable as a Rails engine in any app.

## The problem

Solid Queue ships without a web interface. When jobs fail, queues back up, or workers go silent in production, the only options are `rails console` or raw SQL queries. SolidQueueWeb gives your team a real-time dashboard to inspect, retry, and discard jobs without leaving the browser — and without standing up any additional infrastructure.

## Why SolidQueueWeb?

- Purpose-built for Solid Queue — uses its native models directly, no adapters
- No external CSS framework — drops into any Rails app without asset conflicts
- Zero-config to start — one line in `routes.rb` and you're running
- Built for Rails 8 — Turbo Frames for in-place updates, Stimulus for dynamic search and auto-refresh, Pagy for efficient pagination
- Inspired by Sidekiq Web UI and the GoodJob dashboard, adapted for the Solid Queue ecosystem

## Real-world use case

A Rails app processes order confirmations, email notifications, and report generation through Solid Queue. An operations team needs to:

- Monitor queue depth before a high-traffic event
- Retry a batch of failed notification jobs after a third-party API outage
- Pause a queue while a fix is being deployed
- Identify blocked or long-running jobs before they impact users

SolidQueueWeb surfaces all of this in a browser UI available at any route you choose.

## Features

- **Dashboard** — stat cards showing counts for ready, scheduled, running, blocked, and failed jobs, plus queues, recurring tasks, and processes; auto-refreshes every 5 seconds
- **Queues** — all queues sorted by name with size, latency, and pause/resume controls
- **Jobs** — filterable by status (ready, scheduled, claimed, blocked, failed) and by queue; search by job class name with dynamic auto-submit; time-based period filter (1 h / 24 h / 7 d); discard individual or all jobs; Turbo Frame navigation so only the table updates on filter or search; auto-refreshes every 10 seconds
- **Failed jobs** — list of failed executions with error details; search by class name; filter by queue; time-based period filter; retry or discard individually or in bulk
- **Job detail** — full arguments, timestamps, blocked-until date, and error backtrace; action buttons based on job status
- **Queue management** — pause and resume individual queues; queue-scoped job list with status filter, search, and discard
- **Recurring tasks** — all configured recurring tasks with cron schedule, next run time, last run time, and static/dynamic classification
- **Processes** — workers, dispatchers, and supervisors with heartbeat health status; auto-refreshes every 10 seconds
- **Global search** — search across all job statuses at once by class name substring; results grouped by status with match count and direct links to filtered views; native datalist autocomplete pre-populated from all known job classes; auto-submits on selection

## Screenshots

![SolidQueueWeb dashboard](docs/solid-queue-web.png)

## Compatibility

| Dependency  | Version    |
|-------------|------------|
| Ruby        | >= 3.3     |
| Rails       | >= 8.1.3   |
| Solid Queue | >= 1.0     |

Tested on Ruby 3.3, 3.4, and 4.0.

## Installation

Add to your application's Gemfile:

```ruby
gem "solid_queue_web"
```

Then run:

```bash
bundle install
```

## Mounting the engine

Add to your `config/routes.rb`:

```ruby
mount SolidQueueWeb::Engine, at: "/jobs"
```

The dashboard will be available at `/jobs`. See [Authentication](#authentication) to restrict access to admin users.

## Authentication

The engine ships with no authentication by default. Add a block to an initializer (e.g. `config/initializers/solid_queue_web.rb`) to protect the dashboard:

```ruby
SolidQueueWeb.authenticate do
  # Called in the context of ApplicationController — use any helper available there.
  # Return a truthy value to allow access, falsy to deny (triggers HTTP Basic prompt).
  current_user&.admin?
end
```

HTTP Basic authentication is used as a fallback when the block returns falsy.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/eclectic-coding/solid_queue_web).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).