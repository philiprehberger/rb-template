# philiprehberger-template

[![Tests](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-template.svg)](https://rubygems.org/gems/philiprehberger-template)
[![License](https://img.shields.io/github/license/philiprehberger/rb-template)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Logic-less Mustache-style template engine with safe rendering

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-template"
```

Or install directly:

```bash
gem install philiprehberger-template
```

## Usage

```ruby
require "philiprehberger/template"

# Simple variable interpolation
tpl = Philiprehberger::Template.new('Hello, {{name}}!')
tpl.render(name: 'World')
# => "Hello, World!"

# Load from file
tpl = Philiprehberger::Template.from_file('greeting.mustache')
tpl.render(name: 'World')

# Sections (truthy/falsy)
tpl = Philiprehberger::Template.new('{{#show}}visible{{/show}}')
tpl.render(show: true)   # => "visible"
tpl.render(show: false)  # => ""

# Array iteration
tpl = Philiprehberger::Template.new('{{#items}}* {{name}}\n{{/items}}')
tpl.render(items: [{ name: 'Alice' }, { name: 'Bob' }])
# => "* Alice\n* Bob\n"

# Inverted sections
tpl = Philiprehberger::Template.new('{{^items}}No items found.{{/items}}')
tpl.render(items: [])
# => "No items found."

# Nested scopes (child inherits parent variables)
tpl = Philiprehberger::Template.new('{{#user}}{{greeting}}, {{name}}{{/user}}')
tpl.render(greeting: 'Hi', user: { name: 'Alice' })
# => "Hi, Alice"
```

### Supported Syntax

| Tag | Description |
|-----|-------------|
| `{{var}}` | Variable interpolation (missing variables render as empty string) |
| `{{#section}}...{{/section}}` | Section block (renders if truthy; iterates if array) |
| `{{^section}}...{{/section}}` | Inverted section (renders if falsy or empty) |

## API

| Method | Description |
|--------|-------------|
| `Template.new(source)` | Compile a template string into a renderable template |
| `Template.from_file(path)` | Read a file and compile its contents as a template |
| `#render(variables = {})` | Render the template with the given variable hash |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
