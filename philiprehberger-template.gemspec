# frozen_string_literal: true

require_relative 'lib/philiprehberger/template/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-template'
  spec.version       = Philiprehberger::Template::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Logic-less Mustache-style template engine with safe rendering'
  spec.description   = 'A lightweight Mustache-style template engine supporting variable ' \
                       'interpolation, sections, inverted sections, and nested scopes ' \
                       'with safe rendering that never raises on missing variables.'
  spec.homepage      = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-template'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/philiprehberger/rb-template'
  spec.metadata['changelog_uri']         = 'https://github.com/philiprehberger/rb-template/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/philiprehberger/rb-template/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
