require 'bunny'
require 'erb'
require 'hashie'
require 'yaml'

require_relative 'generic_consumer'

module BunnyFarm

  CONFIG     = Hashie::Mash.new

  def self.config
    if block_given?
      yield
    end

    default :env, 'development'
    default :config_dir, File.dirname(__FILE__) + "/../../config/"
    default :bunny_file, 'bunny.yml.erb'
    default :bunny, Hashie::Mash.new(
                      YAML.load(
                        ERB.new(
                          File.read(
                            File.join(  CONFIG.config_dir,
                                        CONFIG.bunny_file))).result))[CONFIG.env]

    default :app_id, CONFIG.bunny.app_name

    default :connection, Bunny.new(CONFIG.bunny).tap(&:start)

    default :channel, CONFIG.connection.create_channel

    default :exchange, CONFIG.channel.topic(
                                CONFIG.bunny.exchange_name,
                                :durable => true,
                                :auto_delete => false)

    default :queue, CONFIG.channel.queue(
                                    CONFIG.bunny.queue_name,
                                    durable: true,
                                    auto_delete: false,
                                    arguments: {"x-max-length" => 1000}
                                ).bind(CONFIG.exchange,
                                    :routing_key => CONFIG.bunny.routing_key)

    default :control_c, false

    default :consumer_tag, 'generic_consumer'

    default :no_ack, false
    default :exclusive, false

    default :consumer = GenericConsumer.new(
      CONFIG.channel,
      CONFIG.queue,
      CONFIG.consumer_tag,
      CONFIG.no_ack,
      CONFIG.exclusive
    )


  end # def self.config

  def self.default(key, value)
    CONFIG[key] = value if CONFIG[key].nil?
  end

  # FIXME: what I want is to complete forward the
  #        method call, its parameters and a
  #        block to a different object
  def self.on_delivery &block
    CONFIG.consumer.on_delivery block
  end

  # FIXME:
  alias 'on_delivery' 'CONFIG.consumer.on_delivery'
end # module BunnyFarm


trap("INT") do
  BunnyFarm::CONFIG.control_c = true
  exit if $debug
end

at_exit do

  if BunnyFarm::CONFIG.control_c
    STDERR.puts 'Shutting down due to control-C request'
  end

  BunnyFarm::CONFIG.channel.work_pool.shutdown
  BunnyFarm::CONFIG.channel.work_pool.kill if BunnyFarm::CONFIG.channel.work_pool.running?
  BunnyFarm::CONFIG.channel.close
  BunnyFarm::CONFIG.connection.close

end # at_exit do


