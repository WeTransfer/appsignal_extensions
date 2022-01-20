# frozen_string_literal: true

require_relative "lib/appsignal_extensions/version"

Gem::Specification.new do |spec|
  spec.name = "appsignal_extensions"
  spec.version = AppsignalExtensions::VERSION
  spec.authors = ["Julik Tarkhanov", "grdw"]
  spec.email = ["me@julik.nl", "gerard@wetransfer.com"]

  spec.summary = "Suspend an Appsignal transaction for long responses"
  spec.description = "Doing some more with Appsignal"
  spec.homepage = "https://gitlab.wetransfer.net/julik/appsignal_extensions"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency("appsignal", "~> 2")
  spec.add_development_dependency("bundler", "~> 2.0")
  spec.add_development_dependency("rack-test", ">= 0")
  spec.add_development_dependency("rake", "~> 10")
  spec.add_development_dependency("rdoc", "~> 6")
  spec.add_development_dependency("rspec", "~> 3.2.0")
  spec.add_development_dependency("rubocop", "~> 1.21")
end
