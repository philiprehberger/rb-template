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
  end
end
