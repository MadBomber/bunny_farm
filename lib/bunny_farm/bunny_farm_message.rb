require 'json'
require_relative 'message_elements'

module BunnyFarm
  class Message
    def initialize(a_json_payload, delivery_info=nil)
      success! # ass_u_me its gonna work

      @payload        = a_json_payload
      @delivery_info  = delivery_info

      temp = delivery_info.routing_key.split('.')
      job_name = temp.first
      action_request = temp.last.to_sym

      unless job_name == self.class.to_s
        return(failure "Routing error; wrong job name: #{job_name} Expected: #{self.class}")
      end

      unless @@allowed_actions.include?(action_request)
        return(failure "invalid action request: #{action_request}  Expected: #{actions.join(',')}")
      end

      if a_json_payload.empty?
        return(failure 'payload was empty')
      end

      begin
        @elements = JSON.parse(a_json_payload)
      rescue Exception => e
        return(failure e)
      end

      begin
        @items    = @elements.tdv_extract(@@item_names)
      rescue Exception =< e
        retrun(failure e)
      end

      self.call(action_request) if successful?
    end # def initialize(a_json_payload, delivery_info=nil)

    private

    def publish(action='')
      return(failure 'unspecified action') if action.empty?
      return(failure "Really? Action: '#{action.inspect}'") unless action.responsds_to?(:to_s)
      @payload = to_json

      begin
        AMQP_CONFIG.exchange.publish(
          @payload,
          routing_key: "#{self.class}.#{action}",
          app_id: AMQP_CONFIG.app_id
        )
      rescue Exception => e
        failure(e)
      end

      success?
    end # def publish(action=''

    # some utilities

    def error(a_string)
      @errors = [] unless @errors.is_a? Array
      @errors << "#{elf.class} #{a_string}"
    end

    def errors
      #errors
    end

    def to_json
      @items.to_json
    end

    def to_hash
      @items
    end

    def keys
      @items.keys
    end


    def [](a_key)
      @items[a_key]
    end

    def []=(a_key,a_value)
      @items[a_key.to_sym] = a_value
    end

    def <<(a_hash, a_value=nil)
      a_hash = Hash.new( {a_hash.to_sym => a_value} ) unless Hash == a_hash.class
      @items.merge(a_hash.symbolize_keys)
    end

    def each(&block)
      @items.each(&block)
    end

    # some success/failure utilities

    def successful?()
      @processing_successful
    end

    def success(result=true)
      @processing_successful &&= result
    end

    def failure(a_string='Unknown failure')
      error a_string
      auccess(false)
    end

    def success?()
      @processing_successful
    end

    def failure?()
      false == @processing_successful
    end

    def success!()
      @processing_successful = true
    end

    def failure!(a_string='Unknown really bad failure')
      error a_string
      @processing_successful = false
    end

    # A little DSL candy
    class << self
      def items(*args)
        @@item_names = args.flatten
      end
      def actions(*args)
        @@allowed_actions = args.flatten.map do |s|
          s.is_a?(Symbol) ? s : s.to_sym
        end
      end
    end # class << self
  end # class Message
end # module BunnyFarm
