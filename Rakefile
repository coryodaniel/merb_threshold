require 'rubygems'
require 'rake/gempackagetask'

require 'spec/rake/spectask'
require "rake/testtask"

require "spec"
require "spec/rake/spectask"

require 'merb-core'
require 'merb-core/tasks/merb'

GEM_NAME = "merb_threshold"
GEM_VERSION = "1.0.0"
AUTHOR = "Cory O'Daniel"
EMAIL = "contact@coryodaniel.com"
HOMEPAGE = "http://github.com/coryodaniel"
SUMMARY = "Merb plugin that provides resource access rate limits and captcha'ing"

Dir['tasks/**/*.rb'].each do |f|
  puts f
  require f
end

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'merb'
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('merb-core', '>= 1.0.7.1')
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
  
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the plugin as a gem"
task :install do
  Merb::RakeHelper.install(GEM_NAME, :version => GEM_VERSION)
end

desc "Uninstall the gem"
task :uninstall do
  Merb::RakeHelper.uninstall(GEM_NAME, :version => GEM_VERSION)
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end