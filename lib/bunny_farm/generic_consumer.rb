module BunnyFarm
  class GenericConsumer < Bunny::Consumer

    def cancelled?
      @cancelled
    end

    def handle_cancellation(_)
      @cancelled = true
    end
  end # class GenericConsumer < Bunny::Consumer
end # module BunnyFarm
