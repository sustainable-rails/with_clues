require_relative "lib/with_clues/version"

Gem::Specification.new do |spec|
  spec.name = "with_clues"
  spec.version = WithClues::VERSION
  spec.authors       = ["Dave Copeland"]
  spec.email         = ["davec@naildrivin5.com"]
  spec.summary       = %q{Temporarily add context to failing tests to get more information, such as what HTML was being examined when a browser-based test fails.}
  spec.homepage      = "https://sustainable-rails.com"
  spec.license       = "Hippocratic"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sustainable-rails/with_clues"
  spec.metadata["changelog_uri"] = "https://github.com/sustainable-rails/with_clues/releases"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency("rspec")
  spec.add_development_dependency("minitest")
  spec.add_development_dependency("capybara")
  spec.add_development_dependency("rspec_junit_formatter")
end
