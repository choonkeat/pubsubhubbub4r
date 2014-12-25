# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pubsubhubbub4r/version'

Gem::Specification.new do |spec|
  spec.name          = "pubsubhubbub4r"
  spec.version       = Pubsubhubbub4r::VERSION
  spec.authors       = ["choonkeat"]
  spec.email         = ["choonkeat@gmail.com"]
  spec.summary       = %q{Simple pubsubhubbub client lib for Ruby. API is Rails-friendly, not Rails-dependent}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
