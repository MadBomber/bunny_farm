# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bunny_farm/version'

Gem::Specification.new do |spec|
  spec.name          = "bunny_farm"
  spec.version       = BunnyFarm::VERSION
  spec.authors       = ["Dewayne VanHoozer"]
  spec.email         = ["dvanhoozer@gmail.com"]

  spec.summary       = %q{ Simple AMQP/JSON background job manager for RabbitMQ }
  spec.description   = %q{ A lightweight Ruby gem for managing background jobs using RabbitMQ. Messages are encapsulated as classes with JSON serialization and routing keys in the format MessageClassName.action for simple, organized job processing. }
  spec.homepage      = "https://github.com/MadBomber/bunny_farm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "hashie"
  spec.add_dependency "bunny"

  spec.add_development_dependency "bundler" #, "~> 1.8"
  spec.add_development_dependency "rake"    #, "~> 10.0"
  spec.add_development_dependency "minitest"

end
