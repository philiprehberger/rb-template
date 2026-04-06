# frozen_string_literal: true

require_relative 'template/version'
require_relative 'template/parser'
require_relative 'template/renderer'
require_relative 'template/context'
require_relative 'template/filters'
require_relative 'template/cache'

module Philiprehberger
  class Template
    class UndefinedVariableError < StandardError
      attr_reader :variable_name

      def initialize(variable_name)
        @variable_name = variable_name
        super("Undefined variable: #{variable_name}")
      end
    end

    class UndefinedFilterError < StandardError
      attr_reader :filter_name

      def initialize(filter_name)
        @filter_name = filter_name
        super("Undefined filter: #{filter_name}")
      end
    end

    attr_reader :source, :tree

    @partials = {}
    @layouts = {}
    @cache = Cache.new

    class << self
      attr_reader :cache, :partials, :layouts

      def from_file(path, strict: false)
        new(File.read(path), strict: strict)
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

      def registered_partials
        @partials.keys
      end

      def registered_layouts
        @layouts.keys
      end

      def compile(source, strict: false)
        cache_key = [source, strict]
        cached = @cache.fetch(cache_key)
        return cached if cached

        template = new(source, strict: strict)
        @cache.store(cache_key, template)
        template
      end

      def clear_cache!
        @cache.clear
      end
    end

    def initialize(source, strict: false)
      @source = source
      @strict = strict
      @tree = Parser.new(source).parse
    end

    def strict?
      @strict
    end

    def render(variables = {})
      ctx = Context.new(variables)
      Renderer.new(
        @tree,
        ctx,
        partials: self.class.partials,
        layouts: self.class.layouts,
        strict: @strict
      ).render
    end
  end
end
