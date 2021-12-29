# frozen_string_literal: true

module Philiprehberger
  class Template
    class Parser
      def initialize(source)
        @source = source
        @open_delim = '{{'
        @close_delim = '}}'
      end

      def parse
        tokens = tokenize
        build_tree(tokens, nil)
      end

      private

      def tag_pattern
        open = Regexp.escape(@open_delim)
        close = Regexp.escape(@close_delim)
        %r{#{open}(=|[#^/><$]?)(.+?)(?:=#{close}|#{close})}
      end

      def tokenize
        tokens = []
        scanner = @source.dup
        while (match = scanner.match(tag_pattern))
          tokens << [:text, match.pre_match] unless match.pre_match.empty?
          prefix = match[1]
          content = match[2].strip

          if prefix == '='
            # Custom delimiter change: {{= <% %> =}}
            parts = content.split(/\s+/)
            if parts.size == 2
              @open_delim = parts[0]
              @close_delim = parts[1]
              tokens << [:delimiter_change, parts]
            end
          else
            type = tag_type(prefix, content)
            tokens << [type, content]
          end

          scanner = match.post_match
        end
        tokens << [:text, scanner] unless scanner.empty?
        tokens
      end

      def tag_type(prefix, content)
        case prefix
        when '#' then :section_open
        when '^' then :inverted_open
        when '/' then :section_close
        when '>' then :partial
        when '<' then :layout
        when '$' then :block_open
        else
          if content.include?('|')
            :filtered_variable
          else
            :variable
          end
        end
      end

      def build_tree(tokens, closing_tag)
        nodes = []
        while (token = tokens.shift)
          case token[0]
          when :text
            nodes << { type: :text, value: token[1] }
          when :variable
            nodes << { type: :variable, name: token[1] }
          when :filtered_variable
            parts = token[1].split('|').map(&:strip)
            name = parts.shift
            filter_list = parts.map { |f| parse_filter(f) }
            nodes << { type: :filtered_variable, name: name, filters: filter_list }
          when :section_open
            children = build_tree(tokens, token[1])
            raw = extract_raw_source(token[1], children)
            nodes << { type: :section, name: token[1], children: children, raw_content: raw }
          when :inverted_open
            nodes << { type: :inverted, name: token[1], children: build_tree(tokens, token[1]) }
          when :section_close
            if closing_tag
              clean_closing = token[1].strip
              clean_expected = closing_tag.strip
              raise "Mismatched tag: {{/#{token[1]}}}" if clean_closing != clean_expected
            end
            return nodes
          when :partial
            nodes << { type: :partial, name: token[1] }
          when :layout
            nodes << { type: :layout, name: token[1], children: build_tree(tokens, token[1]) }
          when :block_open
            nodes << { type: :block, name: token[1], children: build_tree(tokens, token[1]) }
          when :delimiter_change
            # No node needed; delimiters already changed during tokenization
          end
        end
        nodes
      end

      def parse_filter(filter_str)
        if filter_str.include?('(') && filter_str.end_with?(')')
          name = filter_str[0...filter_str.index('(')]
          arg = filter_str[(filter_str.index('(') + 1)...-1].strip
          # Remove surrounding quotes if present
          arg = arg[1...-1] if (arg.start_with?('"') && arg.end_with?('"')) ||
                               (arg.start_with?("'") && arg.end_with?("'"))
          { name: name.strip, arg: arg }
        else
          { name: filter_str.strip, arg: nil }
        end
      end

      def extract_raw_source(section_name, _children)
        open_tag = "#{@open_delim}##{section_name}#{@close_delim}"
        close_tag = "#{@open_delim}/#{section_name}#{@close_delim}"
        open_idx = @source.index(open_tag)
        return '' unless open_idx

        content_start = open_idx + open_tag.length
        close_idx = @source.index(close_tag, content_start)
        return '' unless close_idx

        @source[content_start...close_idx]
      end
    end
  end
end
