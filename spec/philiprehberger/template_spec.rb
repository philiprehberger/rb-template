# frozen_string_literal: true

require 'spec_helper'

require 'tempfile'

RSpec.describe Philiprehberger::Template do
  describe 'VERSION' do
    it 'returns a valid semver string' do
      expect(Philiprehberger::Template::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '#render' do
    it 'replaces simple variables' do
      tpl = described_class.new('Hello, {{name}}!')
      expect(tpl.render(name: 'World')).to eq('Hello, World!')
    end

    it 'returns empty string for missing variables' do
      tpl = described_class.new('Hello, {{missing}}!')
      expect(tpl.render({})).to eq('Hello, !')
    end

    it 'renders sections for truthy values' do
      tpl = described_class.new('{{#show}}visible{{/show}}')
      expect(tpl.render(show: true)).to eq('visible')
    end

    it 'hides sections for falsy values' do
      tpl = described_class.new('{{#show}}visible{{/show}}')
      expect(tpl.render(show: false)).to eq('')
    end

    it 'iterates over arrays in sections' do
      tpl = described_class.new('{{#items}}[{{name}}]{{/items}}')
      result = tpl.render(items: [{ name: 'a' }, { name: 'b' }])
      expect(result).to eq('[a][b]')
    end

    it 'renders inverted sections for falsy values' do
      tpl = described_class.new('{{^items}}none{{/items}}')
      expect(tpl.render(items: [])).to eq('none')
    end

    it 'hides inverted sections for truthy values' do
      tpl = described_class.new('{{^items}}none{{/items}}')
      expect(tpl.render(items: ['x'])).to eq('')
    end

    it 'resolves nested variables from parent scope' do
      tpl = described_class.new('{{#user}}{{greeting}}, {{name}}{{/user}}')
      result = tpl.render(greeting: 'Hi', user: { name: 'Alice' })
      expect(result).to eq('Hi, Alice')
    end

    it 'handles string keys in variables hash' do
      tpl = described_class.new('{{name}}')
      expect(tpl.render('name' => 'Bob')).to eq('Bob')
    end

    it 'renders empty template' do
      tpl = described_class.new('')
      expect(tpl.render(name: 'test')).to eq('')
    end

    it 'renders template with no variables' do
      tpl = described_class.new('plain text only')
      expect(tpl.render({})).to eq('plain text only')
    end

    it 'renders nil section value as falsy' do
      tpl = described_class.new('{{#item}}shown{{/item}}')
      expect(tpl.render(item: nil)).to eq('')
    end

    it 'renders inverted section for nil value' do
      tpl = described_class.new('{{^item}}fallback{{/item}}')
      expect(tpl.render(item: nil)).to eq('fallback')
    end

    it 'renders inverted section for false value' do
      tpl = described_class.new('{{^active}}inactive{{/active}}')
      expect(tpl.render(active: false)).to eq('inactive')
    end

    it 'hides inverted section for true value' do
      tpl = described_class.new('{{^active}}inactive{{/active}}')
      expect(tpl.render(active: true)).to eq('')
    end

    it 'renders multiple variables in one template' do
      tpl = described_class.new('{{first}} {{last}}')
      expect(tpl.render(first: 'John', last: 'Doe')).to eq('John Doe')
    end

    it 'renders numeric values via to_s' do
      tpl = described_class.new('count: {{num}}')
      expect(tpl.render(num: 42)).to eq('count: 42')
    end

    it 'renders boolean true as string' do
      tpl = described_class.new('val: {{flag}}')
      expect(tpl.render(flag: true)).to eq('val: true')
    end

    it 'renders empty array section as hidden' do
      tpl = described_class.new('before{{#items}}item{{/items}}after')
      expect(tpl.render(items: [])).to eq('beforeafter')
    end

    it 'iterates over single-element array' do
      tpl = described_class.new('{{#items}}[{{val}}]{{/items}}')
      result = tpl.render(items: [{ val: 'only' }])
      expect(result).to eq('[only]')
    end

    it 'handles special characters in values' do
      tpl = described_class.new('{{msg}}')
      expect(tpl.render(msg: '<b>bold & "quoted"</b>')).to eq('<b>bold & "quoted"</b>')
    end

    it 'handles whitespace around variable tags' do
      tpl = described_class.new('{{ name }}')
      expect(tpl.render(name: 'test')).to eq('test')
    end

    it 'preserves whitespace in text nodes' do
      tpl = described_class.new("  hello  \n  world  ")
      expect(tpl.render({})).to eq("  hello  \n  world  ")
    end

    it 'renders nested sections with hash values' do
      tpl = described_class.new('{{#outer}}{{#inner}}deep{{/inner}}{{/outer}}')
      result = tpl.render(outer: { inner: true })
      expect(result).to eq('deep')
    end

    it 'renders section with hash that has nested variables' do
      tpl = described_class.new('{{#user}}{{name}} ({{role}}){{/user}}')
      result = tpl.render(user: { name: 'Alice', role: 'admin' })
      expect(result).to eq('Alice (admin)')
    end

    it 'renders inverted section for missing variable' do
      tpl = described_class.new('{{^missing}}default{{/missing}}')
      expect(tpl.render({})).to eq('default')
    end

    it 'handles mixed sections and variables' do
      tpl = described_class.new('Hello {{name}}! {{#admin}}[admin]{{/admin}}{{^admin}}[user]{{/admin}}')
      expect(tpl.render(name: 'Alice', admin: true)).to eq('Hello Alice! [admin]')
      expect(tpl.render(name: 'Bob', admin: false)).to eq('Hello Bob! [user]')
    end
  end

  describe '#source' do
    it 'exposes the original source template' do
      source = 'Hello, {{name}}!'
      tpl = described_class.new(source)
      expect(tpl.source).to eq(source)
    end
  end

  describe 'Parser' do
    it 'raises on mismatched closing tags' do
      expect do
        described_class.new('{{#open}}text{{/wrong}}')
      end.to raise_error(RuntimeError, /Mismatched tag/)
    end
  end

  describe '.from_file' do
    it 'loads and renders a template from a file' do
      file = Tempfile.new(['template', '.mustache'])
      file.write('Hello, {{name}}!')
      file.close

      tpl = described_class.from_file(file.path)
      expect(tpl.render(name: 'File')).to eq('Hello, File!')
    ensure
      file&.unlink
    end

    it 'loads an empty file' do
      file = Tempfile.new(['empty', '.mustache'])
      file.write('')
      file.close

      tpl = described_class.from_file(file.path)
      expect(tpl.render({})).to eq('')
    ensure
      file&.unlink
    end
  end

  # ── New Feature Tests ──

  describe 'partials' do
    before { described_class.clear_partials! }

    it 'renders a registered partial' do
      described_class.register_partial('header', '<h1>{{title}}</h1>')
      tpl = described_class.new('{{> header}}')
      expect(tpl.render(title: 'Welcome')).to eq('<h1>Welcome</h1>')
    end

    it 'renders an empty string for unregistered partials' do
      tpl = described_class.new('before{{> missing}}after')
      expect(tpl.render({})).to eq('beforeafter')
    end

    it 'renders multiple partials' do
      described_class.register_partial('header', '<h1>{{title}}</h1>')
      described_class.register_partial('footer', '<footer>{{year}}</footer>')
      tpl = described_class.new('{{> header}}{{> footer}}')
      expect(tpl.render(title: 'Hi', year: 2026)).to eq('<h1>Hi</h1><footer>2026</footer>')
    end

    it 'renders partials with variables from context' do
      described_class.register_partial('greeting', 'Hello, {{name}}!')
      tpl = described_class.new('{{> greeting}}')
      expect(tpl.render(name: 'Alice')).to eq('Hello, Alice!')
    end

    it 'renders nested partials' do
      described_class.register_partial('inner', '({{val}})')
      described_class.register_partial('outer', '[{{> inner}}]')
      tpl = described_class.new('{{> outer}}')
      expect(tpl.render(val: 'deep')).to eq('[(deep)]')
    end

    it 'renders partials inside sections' do
      described_class.register_partial('item', '* {{name}}')
      tpl = described_class.new('{{#items}}{{> item}} {{/items}}')
      result = tpl.render(items: [{ name: 'a' }, { name: 'b' }])
      expect(result).to eq('* a * b ')
    end

    it 'clears all partials' do
      described_class.register_partial('test', 'content')
      described_class.clear_partials!
      expect(described_class.partials).to be_empty
    end
  end

  describe 'custom delimiters' do
    it 'changes delimiters mid-template' do
      tpl = described_class.new('{{name}} {{= <% %> =}} <%greeting%>')
      expect(tpl.render(name: 'Alice', greeting: 'Hi')).to eq('Alice  Hi')
    end

    it 'uses new delimiters for sections' do
      tpl = described_class.new('{{= <% %> =}}<%#show%>visible<%/show%>')
      expect(tpl.render(show: true)).to eq('visible')
    end

    it 'uses new delimiters for inverted sections' do
      tpl = described_class.new('{{= <% %> =}}<%^show%>hidden<%/show%>')
      expect(tpl.render(show: false)).to eq('hidden')
    end

    it 'supports ERB-style delimiters' do
      tpl = described_class.new('{{= <% %> =}}<%name%>')
      expect(tpl.render(name: 'test')).to eq('test')
    end

    it 'supports single-character delimiters' do
      tpl = described_class.new('{{= < > =}}<name>')
      expect(tpl.render(name: 'value')).to eq('value')
    end
  end

  describe 'filters' do
    before { Philiprehberger::Template::Filters.reset_custom! }

    it 'applies upcase filter' do
      tpl = described_class.new('{{name | upcase}}')
      expect(tpl.render(name: 'hello')).to eq('HELLO')
    end

    it 'applies downcase filter' do
      tpl = described_class.new('{{name | downcase}}')
      expect(tpl.render(name: 'HELLO')).to eq('hello')
    end

    it 'applies strip filter' do
      tpl = described_class.new('{{name | strip}}')
      expect(tpl.render(name: '  hello  ')).to eq('hello')
    end

    it 'applies escape filter' do
      tpl = described_class.new('{{content | escape}}')
      expect(tpl.render(content: '<b>bold</b>')).to eq('&lt;b&gt;bold&lt;/b&gt;')
    end

    it 'applies capitalize filter' do
      tpl = described_class.new('{{name | capitalize}}')
      expect(tpl.render(name: 'hello world')).to eq('Hello world')
    end

    it 'applies reverse filter' do
      tpl = described_class.new('{{name | reverse}}')
      expect(tpl.render(name: 'hello')).to eq('olleh')
    end

    it 'applies length filter to string' do
      tpl = described_class.new('{{name | length}}')
      expect(tpl.render(name: 'hello')).to eq('5')
    end

    it 'applies length filter to array' do
      tpl = described_class.new('{{items | length}}')
      expect(tpl.render(items: [1, 2, 3])).to eq('3')
    end

    it 'applies default filter for nil value' do
      tpl = described_class.new('{{name | default(N/A)}}')
      expect(tpl.render({})).to eq('N/A')
    end

    it 'applies default filter for empty string' do
      tpl = described_class.new('{{name | default(none)}}')
      expect(tpl.render(name: '')).to eq('none')
    end

    it 'does not apply default filter when value is present' do
      tpl = described_class.new('{{name | default(none)}}')
      expect(tpl.render(name: 'Alice')).to eq('Alice')
    end

    it 'chains multiple filters' do
      tpl = described_class.new('{{name | strip | upcase}}')
      expect(tpl.render(name: '  hello  ')).to eq('HELLO')
    end

    it 'chains three filters' do
      tpl = described_class.new('{{name | strip | downcase | reverse}}')
      expect(tpl.render(name: '  HELLO  ')).to eq('olleh')
    end

    it 'handles unknown filters gracefully' do
      tpl = described_class.new('{{name | nonexistent}}')
      expect(tpl.render(name: 'hello')).to eq('hello')
    end

    it 'supports custom filters' do
      Philiprehberger::Template::Filters.register('shout', ->(val) { "#{val}!!!" })
      tpl = described_class.new('{{name | shout}}')
      expect(tpl.render(name: 'hello')).to eq('hello!!!')
    end

    it 'resets custom filters' do
      Philiprehberger::Template::Filters.register('test', ->(val) { val })
      Philiprehberger::Template::Filters.reset_custom!
      expect(Philiprehberger::Template::Filters.resolve('test')).to be_nil
    end

    it 'applies escape filter with special characters' do
      tpl = described_class.new('{{msg | escape}}')
      expect(tpl.render(msg: '"quotes" & <tags>')).to eq('&quot;quotes&quot; &amp; &lt;tags&gt;')
    end
  end

  describe 'template compilation and caching' do
    before { described_class.clear_cache! }

    it 'compiles and caches a template' do
      tpl1 = described_class.compile('Hello, {{name}}!')
      tpl2 = described_class.compile('Hello, {{name}}!')
      expect(tpl1).to equal(tpl2)
    end

    it 'returns different templates for different sources' do
      tpl1 = described_class.compile('Hello, {{name}}!')
      tpl2 = described_class.compile('Goodbye, {{name}}!')
      expect(tpl1).not_to equal(tpl2)
    end

    it 'renders cached templates correctly' do
      tpl = described_class.compile('{{greeting}}, {{name}}!')
      expect(tpl.render(greeting: 'Hi', name: 'Alice')).to eq('Hi, Alice!')
      expect(tpl.render(greeting: 'Hey', name: 'Bob')).to eq('Hey, Bob!')
    end

    it 'clears the cache' do
      described_class.compile('test')
      described_class.clear_cache!
      expect(described_class.cache.size).to eq(0)
    end

    it 'cache stores compiled templates' do
      described_class.compile('one')
      described_class.compile('two')
      expect(described_class.cache.size).to eq(2)
    end

    it 'cache supports key lookup' do
      described_class.compile('Hello!')
      expect(described_class.cache.key?('Hello!')).to be true
      expect(described_class.cache.key?('Missing')).to be false
    end

    it 'cache supports deletion' do
      described_class.compile('to_delete')
      described_class.cache.delete('to_delete')
      expect(described_class.cache.key?('to_delete')).to be false
    end
  end

  describe 'template inheritance/layouts' do
    before do
      described_class.clear_layouts!
      described_class.clear_partials!
    end

    it 'renders a layout with block overrides' do
      described_class.register_layout('base', '<html>{{$ title}}Default Title{{/title}}</html>')
      tpl = described_class.new('{{< base}}{{$ title}}My Page{{/title}}{{/base}}')
      expect(tpl.render({})).to eq('<html>My Page</html>')
    end

    it 'renders default block content when not overridden' do
      described_class.register_layout('base', '<html>{{$ title}}Default{{/title}}</html>')
      tpl = described_class.new('{{< base}}{{/base}}')
      expect(tpl.render({})).to eq('<html>Default</html>')
    end

    it 'renders multiple blocks in a layout' do
      described_class.register_layout('page', '{{$ header}}H{{/header}}|{{$ body}}B{{/body}}')
      tpl = described_class.new('{{< page}}{{$ header}}MyHeader{{/header}}{{$ body}}MyBody{{/body}}{{/page}}')
      expect(tpl.render({})).to eq('MyHeader|MyBody')
    end

    it 'renders layout with variables' do
      described_class.register_layout('base', '<h1>{{title}}</h1>{{$ content}}default{{/content}}')
      tpl = described_class.new('{{< base}}{{$ content}}Custom content{{/content}}{{/base}}')
      expect(tpl.render(title: 'Hello')).to eq('<h1>Hello</h1>Custom content')
    end

    it 'renders without layout if layout not registered' do
      tpl = described_class.new('{{< missing}}{{$ title}}content{{/title}}{{/missing}}')
      expect(tpl.render({})).to eq('content')
    end

    it 'overrides only specified blocks, keeps defaults for others' do
      described_class.register_layout('base', '{{$ a}}A{{/a}}|{{$ b}}B{{/b}}|{{$ c}}C{{/c}}')
      tpl = described_class.new('{{< base}}{{$ b}}X{{/b}}{{/base}}')
      expect(tpl.render({})).to eq('A|X|C')
    end

    it 'clears all layouts' do
      described_class.register_layout('test', 'content')
      described_class.clear_layouts!
      expect(described_class.layouts).to be_empty
    end
  end

  describe 'lambda support' do
    it 'calls a lambda with raw block content' do
      tpl = described_class.new('{{#bold}}text{{/bold}}')
      result = tpl.render(bold: ->(raw) { "<b>#{raw}</b>" })
      expect(result).to eq('<b>text</b>')
    end

    it 'calls a lambda with no arguments' do
      tpl = described_class.new('{{#timestamp}}ignored{{/timestamp}}')
      result = tpl.render(timestamp: ->(_raw) { '2026-01-01' })
      expect(result).to eq('2026-01-01')
    end

    it 'calls a Proc' do
      wrapper = proc { |raw| "[#{raw}]" }
      tpl = described_class.new('{{#wrap}}content{{/wrap}}')
      expect(tpl.render(wrap: wrapper)).to eq('[content]')
    end

    it 'passes raw template text to lambda (not rendered)' do
      tpl = described_class.new('{{#fn}}{{name}}{{/fn}}')
      captured = nil
      result = tpl.render(
        name: 'Alice',
        fn: lambda { |raw|
          captured = raw
          'replaced'
        }
      )
      expect(captured).to eq('{{name}}')
      expect(result).to eq('replaced')
    end

    it 'lambda can return empty string' do
      tpl = described_class.new('before{{#empty}}content{{/empty}}after')
      result = tpl.render(empty: ->(_raw) { '' })
      expect(result).to eq('beforeafter')
    end

    it 'lambda result is converted to string' do
      tpl = described_class.new('{{#num}}x{{/num}}')
      result = tpl.render(num: ->(_raw) { 42 })
      expect(result).to eq('42')
    end
  end
end
