# Order Processing Example

Comprehensive e-commerce order processing workflow.

```ruby
class OrderMessage < BunnyFarm::Message
  fields :order_id, :customer, :items
  actions :validate, :process, :ship
end
```