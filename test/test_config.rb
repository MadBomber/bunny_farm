require 'minitest_helper'

class TestConfig < Minitest::Test
  def setup
    @valid_keys = [ "env", "config_dir", "bunny_file", "bunny", "app_id", "connection",
                    "channel", "exchange", "queue", "control_c", "consumer_tag", "no_ack",
                    "exclusive", "run", "block"].sort
  end

  def test_config
    # test without block
    refute BunnyFarm::CONFIG.nil?
    assert BunnyFarm::CONFIG.empty?
    assert_equal Hashie::Mash, BunnyFarm::CONFIG.class
    assert_equal [], BunnyFarm::CONFIG.keys

    BunnyFarm.config

    assert_equal @valid_keys, BunnyFarm::CONFIG.keys.sort

    refute BunnyFarm::CONFIG.empty?

    assert_equal Hashie::Mash, BunnyFarm::CONFIG.bunny.class
    assert_equal 'development', BunnyFarm::CONFIG.env

    # test_config_with_block
    assert BunnyFarm::CONFIG.xyzzy.nil?
    BunnyFarm.config do
      xyzzy 123
    end
    assert_equal 123, BunnyFarm::CONFIG.xyzzy, 'testing missing_method, set'
    assert_equal false, BunnyFarm::CONFIG.control_c, 'testing #default'

    # test_run
    assert BunnyFarm::CONFIG.run.respond_to?('on_delivery')

    # test_all_keys_not_nil
    @valid_keys.each do |k|
      refute BunnyFarm::CONFIG[k].nil?, "#{k} should not be nil"
    end

    # test_classes
    assert_equal String, BunnyFarm::CONFIG['app_id'].class, 'Testing class of app_id'
    assert_equal TrueClass, BunnyFarm::CONFIG['block'].class, 'Testing class of block'
    assert_equal Hashie::Mash, BunnyFarm::CONFIG['bunny'].class, 'Testing class of bunny'
    assert_equal String, BunnyFarm::CONFIG['bunny_file'].class, 'Testing class of bunny_file'
    assert_equal Bunny::Channel, BunnyFarm::CONFIG['channel'].class, 'Testing class of channel'
    assert_equal String, BunnyFarm::CONFIG['config_dir'].class, 'Testing class of config_dir'
    assert_equal Bunny::Session, BunnyFarm::CONFIG['connection'].class, 'Testing class of connection'
    assert_equal String, BunnyFarm::CONFIG['consumer_tag'].class, 'Testing class of consumer_tag'
    assert_equal FalseClass, BunnyFarm::CONFIG['control_c'].class, 'Testing class of control_c'
    assert_equal String, BunnyFarm::CONFIG['env'].class, 'Testing class of env'
    assert_equal Bunny::Exchange, BunnyFarm::CONFIG['exchange'].class, 'Testing class of exchange'
    assert_equal FalseClass, BunnyFarm::CONFIG['exclusive'].class, 'Testing class of exclusive'
    assert_equal FalseClass, BunnyFarm::CONFIG['no_ack'].class, 'Testing class of no_ack'
    assert_equal Bunny::Queue, BunnyFarm::CONFIG['queue'].class, 'Testing class of queue'
    assert_equal BunnyFarm::GenericConsumer, BunnyFarm::CONFIG['run'].class, 'Testing class of run'
  end

end # class TestConfig < Minitest::Test
