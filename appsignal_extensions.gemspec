lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appsignal_extensions/version'

Gem::Specification.new do |s|
  s.name = "appsignal_extensions"
  s.version = AppsignalExtensions::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Julik Tarkhanov"]
  s.date = "2016-03-17"
  s.description = "Doing some more with Appsignal"
  s.email = "me@julik.nl"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.homepage = "https://gitlab.wetransfer.net/julik/appsignal_extensions"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Suspend an Appsignal transaction for long responses"
  s.specification_version = 4
  s.add_runtime_dependency(%q<appsignal>, ["~> 1"])
  s.add_development_dependency(%q<rake>, ["~> 10"])
  s.add_development_dependency(%q<rack-test>, [">= 0"])
  s.add_development_dependency(%q<rspec>, ["~> 3.2.0"])
  s.add_development_dependency(%q<rdoc>, ["~> 6"])
  s.add_development_dependency(%q<bundler>, ["~> 1.0"])
end
