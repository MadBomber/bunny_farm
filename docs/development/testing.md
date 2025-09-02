# Testing

Testing strategies for BunnyFarm applications.

## Unit Testing
```ruby
class TestOrderMessage < Minitest::Test
  def test_validation
    message = OrderMessage.new
    message.validate
    assert message.successful?
  end
end
```