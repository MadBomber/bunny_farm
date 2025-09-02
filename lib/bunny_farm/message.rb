require 'json'

require_relative 'message_elements'

module BunnyFarm

  # SNELL: why isn't this:
  #        module Message
  #          class Base
  #        in keeping with the Rails pattern?

  class Message

    # contains the valid fields
    attr_accessor :items

    # contains all the junk sent in the JSON payload
    attr_accessor :elements

    # The JSON payload that was delivered
    attr_accessor :payload

    # The AMQP delivery information
    attr_accessor :delivery_info

    # SMELL: ClassName.new is being used as a dispatcher
    def initialize(a_json_payload='', delivery_info=nil, metadata=nil)
      success! # ass_u_me its gonna work

      @payload        = a_json_payload
      @delivery_info  = delivery_info
      @metadata       = metadata

      if @payload.empty?
        return(failure 'payload was empty')
      end

      if String == @payload.class
        begin
          @elements = MessageElements.new( JSON.parse(@payload) )
        rescue Exception => e
          return(failure e)
        end
      elsif Hash == @payload.class
        begin
          @elements = MessageElements.new( @payload )
        rescue Exception => e
          return(failure e)
        end
      else
        return(failure "payload is unknown class: #{@payload.class}")
      end

      begin
        @items    = @elements.tdv_extract(@@item_names)
      rescue Exception => e
        return(failure e)
      end


      # SMELL: is this necessary if a hash was passed in?
      @payload = to_json unless String == @payload.class


      # NOTE: This is the message dispatcher
      unless @delivery_info.nil?
        params          = @delivery_info.routing_key.split('.')
        job_name        = params.shift
        action_request  = params.shift.to_sym

        unless job_name == self.class.to_s
          return(failure "Routing error; wrong job name: #{job_name} Expected: #{self.class}")
        end

        unless @@allowed_actions.include?(action_request)
          return(failure "invalid action request: #{action_request}  Expected: #{@@allowed_actions.join(',')}")
        end

        if successful?
          self.send(action_request, params)
          if CONFIG.run && CONFIG.run.channel
            CONFIG.run.channel.acknowledge( delivery_info.delivery_tag, false ) if success?
            CONFIG.run.channel.reject( delivery_info.delivery_tag )             if failure? 
          end
        end
      end # unless delivery_info.nil?

    end # def initialize(a_json_payload, delivery_info=nil)


    def publish(action='')
      return(failure "Really? Action: '#{action.inspect}'") unless action.respond_to?(:to_s)
      return(failure 'unspecified action') if action.empty?

      action = action.to_s unless action.is_a?(String)

      # NOTE: that is about all the error checking we can do in a generic
      #       sort of way.  Had thought about checking against #allowed_actions
      #       but realized that there may be a different job manager coordinating
      #       different actions against the same class name.

      @payload = to_json

      begin
        if CONFIG.exchange
          CONFIG.exchange.publish(
            @payload,
            routing_key: "#{self.class}.#{action}",
            app_id: CONFIG.app_id
          )
        else
          failure("undefined method 'publish' for nil")
        end
      rescue Exception => e
        failure(e)
      end

      success?
    end # def publish(action=''

    # some utilities

    def error(a_string)
      @errors = [] unless @errors.is_a? Array
      @errors << "#{self.class} #{a_string}"
      STDERR.puts "ERROR: " + @errors.last
    end

    def errors
      @errors
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

    def <<(a_hash)
      @items.merge!(a_hash.symbolize_keys)
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
      success(false)
    end

    def success?()
      @processing_successful
    end

    def failure?()
      !@processing_successful
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

      # SMELL: These class variables... are they of ::Message or of
      #        its subclass?  If ::Message then that is a problem.
      def fields(*args)
        @@item_names = args.flatten
      end

      def actions(*args)
        @@allowed_actions = args.flatten.map do |s|
          s.is_a?(Symbol) ? s : s.to_sym
        end
      end

      def item_names
        @@item_names
      end

      def allowed_actions
        @@allowed_actions
      end
    end # class << self
  end # class Message
end # module BunnyFarm
