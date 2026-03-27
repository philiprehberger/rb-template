# frozen_string_literal: true

module Philiprehberger
  class Template
    class Parser
      TAG_PATTERN = %r{\{\{([#^/]?)(\s*\w+\s*)\}\}}

      def initialize(source)
        @source = source
      end

      def parse
        tokens = tokenize
        build_tree(tokens, nil)
      end

      private

      def tokenize
        tokens = []
        scanner = @source.dup
        while (match = scanner.match(TAG_PATTERN))
          tokens << [:text, match.pre_match] unless match.pre_match.empty?
          type = tag_type(match[1])
          tokens << [type, match[2].strip]
          scanner = match.post_match
        end
        tokens << [:text, scanner] unless scanner.empty?
        tokens
      end

      def tag_type(prefix)
        { '#' => :section_open, '^' => :inverted_open, '/' => :section_close }.fetch(prefix, :variable)
      end

      def build_tree(tokens, closing_tag)
        nodes = []
        while (token = tokens.shift)
          case token[0]
          when :text then nodes << { type: :text, value: token[1] }
          when :variable then nodes << { type: :variable, name: token[1] }
          when :section_open
            nodes << { type: :section, name: token[1], children: build_tree(tokens, token[1]) }
          when :inverted_open
            nodes << { type: :inverted, name: token[1], children: build_tree(tokens, token[1]) }
          when :section_close
            raise "Mismatched tag: {{/#{token[1]}}}" if closing_tag && token[1] != closing_tag

            return nodes
          end
        end
        nodes
      end
    end
  end
end
