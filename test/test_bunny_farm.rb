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
    @test_payload = @test_hash.to_json
    @mmc = MyMessageClass.new(@test_payload, delivery_stub)
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

  def test_access
    assert_equal 'hello', @mmc[:field1]
    assert_equal 'world', @mmc[:field2]
    assert_equal 'A', @mmc[:field3][:a]
    assert_equal 'B', @mmc[:field3][:b]
    assert_equal 'C', @mmc[:field4][:c]
    assert_equal 'D', @mmc[:field4][:d]
  end

  def test_access_modification
    assert_equal 'goodbye', @mmc[:field1] = 'goodbye'
    assert_equal 'moon', @mmc[:field2] = 'moon'
    assert_equal 'Apple', @mmc[:field3][:a] = 'Apple'
    assert_equal 'Banana', @mmc[:field3][:b] = 'Banana'
    assert_equal 'Cherry', @mmc[:field4][:c] = 'Cherry'
    assert_equal 'Dilbert', @mmc[:field4][:d] = 'Dilbert'

    assert_equal 'goodbye', @mmc[:field1]
    assert_equal 'moon', @mmc[:field2]
    assert_equal 'Apple', @mmc[:field3][:a]
    assert_equal 'Banana', @mmc[:field3][:b]
    assert_equal 'Cherry', @mmc[:field4][:c]
    assert_equal 'Dilbert', @mmc[:field4][:d]

  end

  def test_to_hash
    assert_equal @mmc.items, @mmc.to_hash
  end

  def test_to_json
    assert_equal @mmc.payload, @mmc.to_json
  end

  def test_payload
    assert @mmc.payload.is_a?(String)
    assert_equal @test_payload, @mmc.payload
  end

  def test_insert
    @mmc << {field5: 'Elmer Fudd'}
    assert_equal 5, @mmc.keys.size
    assert_equal 'Elmer Fudd', @mmc[:field5]
    @mmc << {'field6' => 'Rascally Rabbit'}
    assert_equal 6, @mmc.keys.size
    assert_equal 'Rascally Rabbit', @mmc[:field6]
  end

  def test_publish_failure
    result = @mmc.success!
    assert result, 'Its supposed to be true to establish the baseline'
    result = @mmc.publish
    refute result, 'publish was supposed to fail'
    assert_equal 'MyMessageClass unspecified action', @mmc.errors.last
    assert @mmc.failure?
    refute @mmc.successful?
  end

  def test_publish_successful
    result = @mmc.success! # establish baseline
    result = @mmc.publish( 'magic' )
    assert result, 'publish was supposed to succeed'
    refute @mmc.failure?
    assert @mmc.successful?
  end

  def test_errors
    @mmc.error 'test'
    assert @mmc.errors.is_a?(Array), 'errors must be an array'
    assert_equal 'MyMessageClass test', @mmc.errors.last
    assert_equal 1, @mmc.errors.size
  end

end
