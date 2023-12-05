require File.expand_path("../lib/typed_uuid/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "typed_uuid"
  s.version     = TypedUUID::VERSION
  s.authors     = ["Jon Bracy"]
  s.email       = ["jonbracy@gmail.com"]
  s.homepage    = "https://github.com/malomalo/typed_uuid"
  s.summary     = %q{Typed UUIDs for ActiveRecord}
  s.description = %q{Typed UUIDs 2 bytes are reserved in the UUID for the class enum}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Developoment
  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'activesupport', '>= 7.0.0'
  s.add_development_dependency 'rails', '>= 7.0.0'
  s.add_development_dependency 'pg'

  # Runtime
  s.add_runtime_dependency 'activerecord', '>= 7.0.0'
end
