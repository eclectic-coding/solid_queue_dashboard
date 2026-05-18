# SolidQueueWeb

[![Gem Version](https://badge.fury.io/rb/solid_queue_web.svg)](https://rubygems.org/gems/solid_queue_web)

A Rails engine that mounts a monitoring dashboard for [Solid Queue](https://github.com/rails/solid_queue). View queues, inspect jobs by status, browse failed executions, and take action — all without leaving your app.

## Features

- **Dashboard** — stat cards showing counts for ready, scheduled, running, blocked, and failed jobs, plus queues and processes
- **Queues** — all queues sorted by name
- **Jobs** — filterable by status (ready, scheduled, claimed, blocked, failed) and by queue
- **Failed jobs** — list of failed executions with error details
- No external CSS framework — works out of the box

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

The dashboard will be available at `/jobs`.

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

## Requirements

- Ruby >= 3.3
- Rails >= 8.1.3
- solid_queue >= 1.0

## Roadmap

The following features are planned. Contributions welcome.

### Actions on failed jobs
- [ ] Retry a single failed job
- [ ] Discard (delete) a single failed job
- [ ] Bulk retry all failed jobs
- [ ] Bulk discard all failed jobs

### Actions on ready / scheduled jobs
- [ ] Discard (cancel) a single ready or scheduled job
- [ ] Bulk discard all jobs in a queue

### Job detail page
- [ ] Full job details: arguments, priority, attempts, scheduled time
- [ ] Full error backtrace for failed jobs

### Pagination
- [ ] Paginate jobs, failed jobs, and queues lists

### Queue management
- [ ] Pause / resume a queue (block new executions)

### Process visibility
- [ ] Processes page showing workers, dispatchers, and last heartbeat

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/eclectic-coding/solid_queue_web).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).