# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trello_commit/version'

Gem::Specification.new do |spec|
  spec.name          = "trello_commit"
  spec.version       = TrelloCommit::VERSION
  spec.authors       = ["Matthew Patterson"]
  spec.email         = ["matthew.s.patterson@gmail.com"]

  spec.summary       = %q{Bring Trello into your commit messages}
  spec.description   = %q{A wrapper for git commit that helps you pull Trello card data into your commit messages}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize"
  spec.add_dependency "ruby-trello"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
