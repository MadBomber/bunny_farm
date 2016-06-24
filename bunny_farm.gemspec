# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "bunny_farm"
  spec.version       = '0.1.1'
  spec.authors       = ["Dewayne VanHoozer"]
  spec.email         = ["dvanhoozer@gmail.com"]

  spec.summary       = %q{ My opinion on how intelligent messages could be handled. }
  spec.description   = %q{ Everyone has an opinion. This is mine. }
  spec.homepage      = "https://github.com/MadBomber/bunny_farm"
  spec.license       = "You want it?  Its yours!"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "hashie"
  spec.add_dependency "bunny"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"

end
