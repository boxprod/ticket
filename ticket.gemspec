require_relative "lib/ticket/version"

Gem::Specification.new do |spec|
  spec.name        = "ticket"
  spec.version     = Ticket::VERSION
  spec.authors     = [ "B.O.X" ]
  spec.homepage    = "https://github.com/boxprod/ticket"
  spec.summary     = "A feedback button for Rails apps that files GitHub issues."
  spec.description = "Lets the people using an app report a bug, an idea or a question, with a screenshot, without a GitHub account. Each report becomes an issue in the app's repository."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3"

  # Private: installed from GitHub, never pushed to RubyGems.
  spec.metadata["allowed_push_host"] = "https://rubygems.invalid"
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0"
end
