# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../lib', __FILE__))
require 'fp/node/version'

Gem::Specification.new do |s|
  s.name         = 'fp-node'
  s.version      = FP::VERSION
  s.platform     = Gem::Platform::RUBY
  s.summary      = 'NiceScale global variables helper library'
  s.description  = "NiceScale management utils"
  s.author       = 'mountkin'
  s.homepage     = 'http://firstpaas.com'
  s.license      = 'Apache 2.0'
  s.email        = 'mountkin@gmail.com'
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  s.files        = Dir.glob('**/*').select { |x| File.file? x }
  s.require_path = 'lib'
  
  s.add_dependency 'parseconfig'
  s.add_development_dependency 'rspec'
end
