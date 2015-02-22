require_relative 'hash_ext'

class MessageElements < Hash

  def initialize(*args)

    super()

    # SMELL: flatten _assumes_ that there is no structure
    #        to the JSON message being handled.  Why did I
    #        do it this way?  Might have been to ensure that
    #        all the hash keys were symbolized.  I need a
    #        deep symbolize_keys.

    if args.size > 0
      args.flatten.each do |a|
        if a.is_a? Hash
          self.merge!(a.deep_symbolize_keys)
        else
          self[a.to_sym]=nil
        end
      end # args.flatten.each do |a|
    end # if args.size > 0
  end # def initialize(*args)
end # class MessageElements < Hash
