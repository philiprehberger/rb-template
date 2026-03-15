# frozen_string_literal: true

require_relative 'template/version'
require_relative 'template/parser'
require_relative 'template/renderer'
require_relative 'template/context'

module Philiprehberger
  class Template
    attr_reader :source, :tree

    def self.from_file(path)
      new(File.read(path))
    end

    def initialize(source)
      @source = source
      @tree = Parser.new(source).parse
    end

    def render(variables = {})
      ctx = Context.new(variables)
      Renderer.new(@tree, ctx).render
    end
  end
end
