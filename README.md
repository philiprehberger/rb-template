# philiprehberger-template

[![Tests](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml) [![Gem Version](https://img.shields.io/gem/v/philiprehberger-template)](https://rubygems.org/gems/philiprehberger-template) [![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-template)](https://github.com/philiprehberger/rb-template/releases) [![GitHub last commit](https://img.shields.io/github/last-commit/philiprehberger/rb-template)](https://github.com/philiprehberger/rb-template/commits/main) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Bug Reports](https://img.shields.io/badge/bug-reports-red.svg)](https://github.com/philiprehberger/rb-template/issues) [![Feature Requests](https://img.shields.io/badge/feature-requests-blue.svg)](https://github.com/philiprehberger/rb-template/issues) [![GitHub Sponsors](https://img.shields.io/badge/sponsor-philiprehberger-ea4aaa.svg?logo=github)](https://github.com/sponsors/philiprehberger)

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

### Basic Variables

```ruby
require "philiprehberger/template"

tpl = Philiprehberger::Template.new("Hello, {{name}}!")
tpl.render(name: "World")
# => "Hello, World!"
```

### Load from File

```ruby
tpl = Philiprehberger::Template.from_file("greeting.mustache")
tpl.render(name: "World")
```

### Sections and Inverted Sections

```ruby
# Truthy/falsy sections
tpl = Philiprehberger::Template.new("{{#show}}visible{{/show}}")
tpl.render(show: true)   # => "visible"
tpl.render(show: false)  # => ""

# Array iteration
tpl = Philiprehberger::Template.new("{{#items}}* {{name}}\n{{/items}}")
tpl.render(items: [{ name: "Alice" }, { name: "Bob" }])
# => "* Alice\n* Bob\n"

# Inverted sections
tpl = Philiprehberger::Template.new("{{^items}}No items found.{{/items}}")
tpl.render(items: [])
# => "No items found."

# Nested scopes (child inherits parent variables)
tpl = Philiprehberger::Template.new("{{#user}}{{greeting}}, {{name}}{{/user}}")
tpl.render(greeting: "Hi", user: { name: "Alice" })
# => "Hi, Alice"
```

### Partials

```ruby
Philiprehberger::Template.register_partial("header", "<h1>{{title}}</h1>")
Philiprehberger::Template.register_partial("footer", "<footer>{{year}}</footer>")

tpl = Philiprehberger::Template.new("{{> header}}<main>{{content}}</main>{{> footer}}")
tpl.render(title: "Home", content: "Welcome!", year: 2026)
# => "<h1>Home</h1><main>Welcome!</main><footer>2026</footer>"

Philiprehberger::Template.clear_partials!
```

### Custom Delimiters

```ruby
tpl = Philiprehberger::Template.new("{{name}} {{= <% %> =}} <%greeting%>")
tpl.render(name: "Alice", greeting: "Hi")
# => "Alice  Hi"
```

### Filters

```ruby
# Single filter
tpl = Philiprehberger::Template.new("{{name | upcase}}")
tpl.render(name: "hello")
# => "HELLO"

# Chained filters
tpl = Philiprehberger::Template.new("{{name | strip | upcase}}")
tpl.render(name: "  hello  ")
# => "HELLO"

# Default filter with argument
tpl = Philiprehberger::Template.new("{{name | default(Anonymous)}}")
tpl.render({})
# => "Anonymous"

# HTML escaping
tpl = Philiprehberger::Template.new("{{content | escape}}")
tpl.render(content: "<script>alert('xss')</script>")
# => "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"

# Custom filters
Philiprehberger::Template::Filters.register("shout", ->(val) { "#{val}!!!" })
tpl = Philiprehberger::Template.new("{{name | shout}}")
tpl.render(name: "hello")
# => "hello!!!"
```

Built-in filters: `upcase`, `downcase`, `strip`, `escape`, `capitalize`, `reverse`, `length`, `default`.

### Template Compilation and Caching

```ruby
# Compile once, render many times with different data
tpl = Philiprehberger::Template.compile("Hello, {{name}}!")
tpl.render(name: "Alice")  # => "Hello, Alice!"
tpl.render(name: "Bob")    # => "Hello, Bob!"

# Same source returns the cached template instance
tpl2 = Philiprehberger::Template.compile("Hello, {{name}}!")
tpl.equal?(tpl2)  # => true

Philiprehberger::Template.clear_cache!
```

### Template Inheritance/Layouts

```ruby
Philiprehberger::Template.register_layout("base", <<~LAYOUT)
  <html>
  <head>{{$ title}}Default Title{{/title}}</head>
  <body>{{$ body}}Default Body{{/body}}</body>
  </html>
LAYOUT

tpl = Philiprehberger::Template.new("{{< base}}{{$ title}}My Page{{/title}}{{$ body}}Hello!{{/body}}{{/base}}")
tpl.render({})
# Renders layout with "My Page" as title and "Hello!" as body

Philiprehberger::Template.clear_layouts!
```

### Lambda Support

```ruby
tpl = Philiprehberger::Template.new("{{#bold}}text{{/bold}}")
tpl.render(bold: ->(raw) { "<b>#{raw}</b>" })
# => "<b>text</b>"

# Lambdas receive the raw (unrendered) block text
tpl = Philiprehberger::Template.new("{{#wrap}}{{name}}{{/wrap}}")
tpl.render(name: "Alice", wrap: ->(raw) { "[#{raw}]" })
# => "[{{name}}]"
```

## API

| Method | Description |
|--------|-------------|
| `Template.new(source)` | Compile a template string into a renderable template |
| `Template.from_file(path)` | Read a file and compile its contents as a template |
| `Template.compile(source)` | Compile and cache a template for repeated rendering |
| `Template.register_partial(name, source)` | Register a named partial template |
| `Template.clear_partials!` | Remove all registered partials |
| `Template.register_layout(name, source)` | Register a named layout template |
| `Template.clear_layouts!` | Remove all registered layouts |
| `Template.clear_cache!` | Clear the compiled template cache |
| `Template.cache` | Access the template cache instance |
| `Filters.register(name, callable)` | Register a custom filter |
| `Filters.reset_custom!` | Remove all custom filters |
| `#render(variables = {})` | Render the template with the given variable hash |
| `#source` | Returns the original template source string |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Philip%20Rehberger-blue?logo=linkedin)](https://linkedin.com/in/philiprehberger) [![More Packages](https://img.shields.io/badge/more-packages-blue.svg)](https://github.com/philiprehberger?tab=repositories)

## License

[MIT](LICENSE)
