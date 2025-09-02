# Task Scheduler Example

Scheduled task execution with retry logic.

```ruby
class ScheduledTask < BunnyFarm::Message
  actions :schedule, :execute
end
```