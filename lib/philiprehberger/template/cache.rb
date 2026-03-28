# frozen_string_literal: true

module Philiprehberger
  class Template
    class Cache
      def initialize
        @store = {}
      end

      def fetch(key)
        @store[key]
      end

      def store(key, compiled_template)
        @store[key] = compiled_template
      end

      def delete(key)
        @store.delete(key)
      end

      def clear
        @store.clear
      end

      def size
        @store.size
      end

      def key?(key)
        @store.key?(key)
      end
    end
  end
end
