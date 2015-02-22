require 'minitest_helper'

class TestBunnyFarm < Minitest::Test
  def setup
    @test_hash = {
      field1: 'hello',
      field2: 'world',
      field3: {a: 'A', b: 'B'},
      field4: {c: 'C', d: 'D'}
    }
    delivery_stub = Hashie::Mash.new
    delivery_stub.routing_key = 'MyMessageClass.test'
    @mmc = MyMessageClass.new(@test_hash.to_json, delivery_stub)
  end

  def test_that_it_has_a_version_number
    refute_nil ::BunnyFarm::VERSION
  end

  def test_class_inherence
    assert @mmc.is_a?(MyMessageClass), "Expected MyMessageClass got #{@mmc.class}"
    assert @mmc.is_a?(BunnyFarm::Message), "Expected BunnyFarm::Message"
    assert @mmc.items.is_a?(Hash), "Expected Hash got #{@mmc.items.class} Errprs: #{@mmc.errors}"
    assert @mmc.elements.is_a?(Hash), "Expected Hash got #{@mmc.elements.class}"
    assert @mmc.payload.is_a?(String), "Expected String got #{@mmc.payload.class}"
    assert @mmc.delivery_info.is_a?(Hashie::Mash), "Expected Hashie::Mash got #{@mmc.delivery_info.class}"
  end
end
