# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'log_spy/version'

Gem::Specification.new do |spec|
  spec.name          = "log_spy"
  spec.version       = LogSpy::VERSION
  spec.authors       = ["Yang-Hsing Lin"]
  spec.email         = ["yanghsing.lin@gmail.com"]
  spec.summary       = %q{ send rack application log to Amazon SQS }
  spec.description   = %q{ LogSpy is a rack middleware sending request log to Amazon SQS }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "rack"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
