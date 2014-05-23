# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../lib', __FILE__))
require 'fp/vars'

Gem::Specification.new do |s|
  s.name         = 'fp-vars'
  s.version      = FP::Vars::VERSION
  s.platform     = Gem::Platform::RUBY
  s.summary      = 'FirstPaaS global variables helper library'
  s.description  = "#{`git rev-parse HEAD`[0, 6]}"
  s.author       = 'mountkin'
  s.homepage     = 'http://firstpaas.com'
  s.license      = 'Apache 2.0'
  s.email        = 'mountkin@gmail.com'
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  s.files        = `git ls-files -- *`.split("\n")
  s.require_path = 'lib'
  
  s.add_dependency 'parseconfig'
  s.add_development_dependency 'rspec'
end
