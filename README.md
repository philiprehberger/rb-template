# philiprehberger-template

[![Gem Version](https://badge.fury.io/rb/philiprehberger-template.svg)](https://badge.fury.io/rb/philiprehberger-template)
[![CI](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml)

Logic-less Mustache-style template engine with safe rendering for Ruby.

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-template'
```

Or install directly:

```
gem install philiprehberger-template
```

## Usage

```ruby
require 'philiprehberger/template'

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

## Supported Syntax

| Tag | Description |
|-----|-------------|
| `{{var}}` | Variable interpolation (missing variables render as empty string) |
| `{{#section}}...{{/section}}` | Section block (renders if truthy; iterates if array) |
| `{{^section}}...{{/section}}` | Inverted section (renders if falsy or empty) |

## API

### `Philiprehberger::Template.new(source)`

Compiles a template string into a renderable template.

### `Philiprehberger::Template.from_file(path)`

Reads a file and compiles its contents as a template.

### `#render(variables = {})`

Renders the template with the given variable hash. Accepts both symbol and string keys. Missing variables produce an empty string.

## Development

```
bundle install
bundle exec rake spec
bundle exec rake rubocop
```

## License

MIT License. See [LICENSE](LICENSE) for details.
