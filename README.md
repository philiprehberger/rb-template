# philiprehberger-template

[![Tests](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-template/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-template.svg)](https://rubygems.org/gems/philiprehberger-template)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-template)](https://github.com/philiprehberger/rb-template/commits/main)

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

tpl = Philiprehberger::Template.new("Hello, {{name}}!")
tpl.render(name: "World")
# => "Hello, World!"
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

### Comments

```ruby
# Comments are stripped from rendered output
tpl = Philiprehberger::Template.new("Hello{{! This is a comment }} World")
tpl.render({})
# => "Hello World"

# Multi-line comments
tpl = Philiprehberger::Template.new("Hello{{! this is\na multi-line comment }}World")
tpl.render({})
# => "HelloWorld"
```

### Strict Mode

```ruby
# Raises UndefinedVariableError for missing variables
tpl = Philiprehberger::Template.new("Hello, {{name}}!", strict: true)
tpl.render(name: "World")  # => "Hello, World!"
tpl.render({})             # => raises UndefinedVariableError

# Raises UndefinedFilterError for unknown filters
tpl = Philiprehberger::Template.new("{{name | bogus}}", strict: true)
tpl.render(name: "hi")     # => raises UndefinedFilterError

# Default mode renders empty string for missing variables
tpl = Philiprehberger::Template.new("Hello, {{name}}!")
tpl.render({})
# => "Hello, !"
```

### Whitespace Control

```ruby
# Strip whitespace before the tag
tpl = Philiprehberger::Template.new("Hello   {{~ name }}")
tpl.render(name: "World")
# => "HelloWorld"

# Strip whitespace after the tag
tpl = Philiprehberger::Template.new("{{ name ~}}   there")
tpl.render(name: "Hello")
# => "Hellothere"

# Strip both sides
tpl = Philiprehberger::Template.new("Hello   {{~ name ~}}   World")
tpl.render(name: ", ")
# => "Hello, World"
```

## API

| Method | Description |
|--------|-------------|
| `Template.new(source, strict: false)` | Compile a template string into a renderable template |
| `Template.from_file(path, strict: false)` | Read a file and compile its contents as a template |
| `Template.compile(source, strict: false)` | Compile and cache a template for repeated rendering |
| `Template.register_partial(name, source)` | Register a named partial template |
| `Template.clear_partials!` | Remove all registered partials |
| `Template.register_layout(name, source)` | Register a named layout template |
| `Template.clear_layouts!` | Remove all registered layouts |
| `Template.registered_partials` | List names of all registered partials |
| `Template.registered_layouts` | List names of all registered layouts |
| `Template.clear_cache!` | Clear the compiled template cache |
| `Template.cache` | Access the template cache instance |
| `Filters.register(name, callable)` | Register a custom filter |
| `Filters.reset_custom!` | Remove all custom filters |
| `#render(variables = {})` | Render the template with the given variable hash |
| `#source` | Returns the original template source string |
| `#strict?` | Returns whether the template uses strict mode |

### Thread Safety

Note: `Template.register_partial`, `Template.register_layout`, and the compilation cache are class-level shared state. If you register partials or layouts from multiple threads simultaneously, wrap the calls in a Mutex.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-template)

🐛 [Report issues](https://github.com/philiprehberger/rb-template/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-template/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
