
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |spec|
  spec.name          = "ulock"
  spec.version       = Ulock::VERSION
  spec.authors       = ["Rob Cobb"]
  spec.email         = ["rwcobbjr@gmail.com"]

  spec.summary       = %q{Teensy wrapper around gpg, mostly to make it easier to lock up my project euler files}
  spec.license       = "MIT"

  spec.files         = ['lib/ulock.rb', 'lib/version.rb']
  spec.executables   << 'ulock'
  spec.require_paths = ["lib"]
  spec.bindir = 'bin'

  spec.add_runtime_dependency "commander"
  spec.add_runtime_dependency "tty-prompt"
  spec.add_runtime_dependency "tty-progressbar"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.requirements << "gpg"
end
