# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sapanywhere/version'

Gem::Specification.new do |spec|
  spec.name          = "sapanywhere"
  spec.version       = Sapanywhere::VERSION
  spec.authors       = ["liangyuzhe"]
  spec.email         = ["2459889179@qq.com"]

  spec.summary       = %q{sap_anywhere的接口封装.}
  spec.description   = %q{sap_anywhere的接口封装.}
  spec.homepage      = "https://github.com/liangyuzhe/inteface"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'rest-client'
  spec.add_development_dependency 'rails', '4.2.5'


end
