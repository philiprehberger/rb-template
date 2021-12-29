# frozen_string_literal: true

require_relative 'template/version'
require_relative 'template/parser'
require_relative 'template/renderer'
require_relative 'template/context'
require_relative 'template/filters'
require_relative 'template/cache'

module Philiprehberger
  class Template
    attr_reader :source, :tree

    @partials = {}
    @layouts = {}
    @cache = Cache.new

    class << self
      attr_reader :cache, :partials, :layouts

      def from_file(path)
        new(File.read(path))
      end

      def register_partial(name, source)
        @partials[name.to_s] = source
      end

      def clear_partials!
        @partials = {}
      end

      def register_layout(name, source)
        @layouts[name.to_s] = source
      end

      def clear_layouts!
        @layouts = {}
      end

      def compile(source)
        cached = @cache.fetch(source)
        return cached if cached

        template = new(source)
        @cache.store(source, template)
        template
      end

      def clear_cache!
        @cache.clear
      end
    end

    def initialize(source)
      @source = source
      @tree = Parser.new(source).parse
    end

    def render(variables = {})
      ctx = Context.new(variables)
      Renderer.new(
        @tree,
        ctx,
        partials: self.class.partials,
        layouts: self.class.layouts
      ).render
    end
  end
end
