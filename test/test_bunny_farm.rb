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

  def test_allowed_actions
    assert MyMessageClass.allowed_actions.is_a?(Array), "Expected Array got: #{MyMessageClass.allowed_actions.class}"
    assert_equal 1, MyMessageClass.allowed_actions.size, "number of allowed actions is wrong"
    assert_equal :test, MyMessageClass.allowed_actions.first, ":test is the only allowed action not #{MyMessageClass.allowed_actions.first.inspect}"
  end

  def test_item_names
    assert MyMessageClass.item_names.is_a?(Array), "Expected Array got: #{MyMessageClass.item_names.class}"
    assert_equal 4, MyMessageClass.item_names.size, "Number of item_names is wrong"
    assert_equal :field1, MyMessageClass.item_names[0]
    assert_equal :field2, MyMessageClass.item_names[1]
    (2..3).each do |x|
      assert MyMessageClass.item_names[x].is_a?(Hash), 'should be a Hash'
      assert_equal 1, MyMessageClass.item_names[x].size, 'should have only one key'
      assert MyMessageClass.item_names[x].first.is_a?(Array), 'should be an Array'
      assert_equal 2, MyMessageClass.item_names[x].first.size, 'should only have two entries'
    end
  end

  def test_keys
    assert_equal 4, @mmc.keys.size, 'Number of keys is wrong'
  end

  def test_items
    assert_equal 4, @mmc.items.size, 'wrong number of items'
    (1..4).each do |x|
      assert @mmc.items.include?("field#{x}".to_sym), "Where is :field#{x}"
    end
    assert_equal 'hello', @mmc.items[:field1], 'where is my hello'
    assert_equal 'world', @mmc.items[:field2], 'the world is not enought'
    (3..4).each do |x|
      key = "field#{x}".to_sym
      assert @mmc.items[key].is_a?(Hash), 'field is not componund'
      assert_equal 2, @mmc.items[key].size, 'wrong number of sub_keys'
      sub_keys = @mmc.items[key].keys
      sub_keys.each do |k|
        assert_equal k.to_s.upcase, @mmc.items[key][k], 'value is upcase of key'
      end
    end
  end

end
