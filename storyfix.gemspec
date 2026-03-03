require_relative "lib/storyfix/version"

Gem::Specification.new do |spec|
  spec.name = "storyfix"
  spec.version = Storyfix::VERSION
  spec.authors = ["Dave Brady"]
  spec.email = ["dbrady@shinybit.com"]
  spec.summary = "CLI tool to apply LLM fixes to text via OpenRouter"
  spec.description = "StoryFix transforms text by applying user-defined fixes through OpenRouter LLMs"
  spec.homepage = "https://github.com/dbrady/storyfix"
  spec.required_ruby_version = ">= 3.4.8"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[test/ spec/ features/ .git .beads])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["storyfix"]
  spec.require_paths = ["lib"]

  spec.add_dependency "optimist"
  spec.add_dependency "colorize"
  spec.add_dependency "extralite"
end
