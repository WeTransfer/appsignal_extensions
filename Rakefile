# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require_relative 'lib/appsignal_extensions/version'
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.version = AppsignalExtensions::VERSION
  gem.name = "appsignal_extensions"
  gem.homepage = "https://gitlab.wetransfer.net/julik/appsignal_extensions"
  gem.license = "MIT"
  gem.description = %Q{Doing some more with Appsignal}
  gem.summary = %Q{Suspend an Appsignal transaction for long responses}
  gem.email = "me@julik.nl"
  gem.authors = ["Julik Tarkhanov"]
  # dependencies defined in Gemfile
end
# Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "appsignal_extensions #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
