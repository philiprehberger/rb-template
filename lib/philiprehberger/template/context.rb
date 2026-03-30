# frozen_string_literal: true

module Philiprehberger
  class Template
    class Context
      def initialize(variables = {})
        @stack = [normalize(variables)]
      end

      def lookup(name)
        key = name.to_sym
        @stack.reverse_each do |scope|
          return scope[key] if scope.key?(key)
        end
        nil
      end

      def defined?(name)
        key = name.to_sym
        @stack.reverse_each do |scope|
          return true if scope.key?(key)
        end
        false
      end

      def push(scope)
        @stack.push(normalize(scope))
      end

      def pop
        @stack.pop if @stack.size > 1
      end

      private

      def normalize(hash)
        hash.transform_keys(&:to_sym)
      end
    end
  end
end
