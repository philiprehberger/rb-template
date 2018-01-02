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
end
