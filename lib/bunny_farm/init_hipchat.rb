require 'erb'
require 'hashie'
require 'json'
require 'net/http'
require 'yaml'

# TODO: need to make the location of the config directory
#       a parameter

HIPCHAT_CONFIG = Hashie::Mash.new(
                    YAML.load(
                      ERB.new(
                        File.read(
                          File.join(JOB_CONFIG.root, 'config/hipchat.yml.erb'))).result))[JOB_CONFIG.env]

# TODO: Consider a generic Notifier base class and let
#       HipchatNotifier inherent from it
class HipchatNotifier

  def initialize(config)

    @uri = URI.parse("https://api.hipchat.com/v2/room/#{config.room}/notification?auth_token=#{config.token}")

    @http = Net::HTTP.new(@uri.host, @uri.port)

    @http.use_ssl = true

    @request = Net::HTTP::Post.new(@uri.request_uri, {'Content-Type' => 'application/json'})

  end # def initialize(config)


  def notify(a_message)

    @request.body = {
      "notify"          => true,
      "message_format"  => "text",
      "message"         => "#{JOB_CONFIG.my_name} #{a_message}"
    }.to_json

    @http.request(@request)

  end # def notify(a_message)
end # class HipchatNotifier

JOB_CONFIG.notifier = HipchatNotifier.new(HIPCHAT_CONFIG)
JOB_CONFIG.log.info('Hipchat notifier has been initialized')


