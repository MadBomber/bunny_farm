require 'bunny'
require 'erb'
require 'hashie'
require 'yaml'

# TODO: need to make the location of the config directory
#       a parameter

bunny_config = Hashie::Mash.new(
                  YAML.load(
                    ERB.new(
                      File.read(
                        File.join(JOB_CONFIG.root, 'config/bunny.yml.erb'))).result))[JOB_CONFIG.env]

AMQP_CONFIG     = Hashie::Mash.new

AMQP_CONFIG.app_id     = bunny_config.app_name

debug_me('BEFORE Establishing Connection'){[ :AMQP_CONFIG, :bunny_config ]} if $debug

AMQP_CONFIG.connection = Bunny.new(bunny_config).tap(&:start)
AMQP_CONFIG.channel    = AMQP_CONFIG.connection.create_channel

AMQP_CONFIG.exchange   = AMQP_CONFIG.channel.topic(
                            bunny_config.exchange_name,
                            :durable => true,
                            :auto_delete => false)

AMQP_CONFIG.queue      = AMQP_CONFIG.channel.queue(
                                bunny_config.queue_name,
                                durable: true,
                                auto_delete: false,
                                arguments: {"x-max-length" => 1000}
                            ).bind(AMQP_CONFIG.exchange,
                                :routing_key => bunny_config.routing_key)

# NOTE: routing_key by convention is object.action
#       For this job, object is a formal class name and
#       action is a valid method for that class.

class GenericConsumer < Bunny::Consumer

  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end

end # class SubmissionConsumer < Bunny::Consumer

AMQP_CONFIG.control_c = false

trap("INT") do
  AMQP_CONFIG.control_c = true
  exit if $debug
end

at_exit do

  if AMQP_CONFIG.control_c
    # TODO: mitigate the worse thing that could happen
    a_message = 'Shutting down due to control-C request'
  end

  AMQP_CONFIG.channel.work_pool.shutdown
  AMQP_CONFIG.channel.work_pool.kill if AMQP_CONFIG.channel.work_pool.running?
  AMQP_CONFIG.channel.close
  AMQP_CONFIG.connection.close

end # at_exit do


