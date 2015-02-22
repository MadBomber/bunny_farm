$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bunny_farm'

require 'minitest/autorun'
require 'hashie'

class MyMessageClass < BunnyFarm::Message
  fields :field1, :field2, {field3: [:a, :b]}, {field4: [:c, :d]}
  actions :test
  def test
    success!
  end
end
