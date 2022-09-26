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
        apply_whitespace_control(tokens)
        build_tree(tokens, nil)
      end

      private

      def tag_pattern
        open = Regexp.escape(@open_delim)
        close = Regexp.escape(@close_delim)
        %r{#{open}(=|[!#^/><$]?)(.+?)(?:=#{close}|#{close})}m
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
          elsif prefix == '!'
            # Comment — strip from output entirely
            tokens << [:comment, content]
          else
            type, parsed_content = parse_tag(prefix, content)
            tokens << [type, parsed_content]
          end

          scanner = match.post_match
        end
        tokens << [:text, scanner] unless scanner.empty?
        tokens
      end

      def parse_tag(prefix, content)
        strip_before = false
        strip_after = false

        # Check for whitespace control markers on the content
        if prefix.empty? || prefix == '#' || prefix == '^' || prefix == '/' ||
           prefix == '>' || prefix == '<' || prefix == '$'
          if content.start_with?('~')
            strip_before = true
            content = content[1..].strip
          end
          if content.end_with?('~')
            strip_after = true
            content = content[0...-1].strip
          end
        end

        type = tag_type(prefix, content)
        parsed = { value: content, strip_before: strip_before, strip_after: strip_after }
        [type, parsed]
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

      def apply_whitespace_control(tokens)
        tokens.each_with_index do |token, i|
          next if %i[text delimiter_change comment].include?(token[0])

          meta = token[1]
          next unless meta.is_a?(Hash)

          if meta[:strip_before] && i.positive? && tokens[i - 1][0] == :text
            # Strip trailing whitespace (spaces/tabs) from the preceding text node
            tokens[i - 1][1] = tokens[i - 1][1].sub(/[ \t]+\z/, '')
          end

          if meta[:strip_after] && i < tokens.size - 1 && tokens[i + 1][0] == :text
            # Strip leading whitespace (spaces/tabs) from the following text node
            tokens[i + 1][1] = tokens[i + 1][1].sub(/\A[ \t]+/, '')
          end
        end
      end

      def build_tree(tokens, closing_tag)
        nodes = []
        while (token = tokens.shift)
          case token[0]
          when :text
            nodes << { type: :text, value: token[1] }
          when :comment
            # Comments are stripped entirely — no node emitted
            next
          when :variable
            nodes << { type: :variable, name: token[1][:value] }
          when :filtered_variable
            parts = token[1][:value].split('|').map(&:strip)
            name = parts.shift
            filter_list = parts.map { |f| parse_filter(f) }
            nodes << { type: :filtered_variable, name: name, filters: filter_list }
          when :section_open
            tag_name = token[1][:value]
            children = build_tree(tokens, tag_name)
            raw = extract_raw_source(tag_name, children)
            nodes << { type: :section, name: tag_name, children: children, raw_content: raw }
          when :inverted_open
            tag_name = token[1][:value]
            nodes << { type: :inverted, name: tag_name, children: build_tree(tokens, tag_name) }
          when :section_close
            if closing_tag
              clean_closing = token[1][:value].strip
              clean_expected = closing_tag.strip
              raise "Mismatched tag: {{/#{token[1][:value]}}}" if clean_closing != clean_expected
            end
            return nodes
          when :partial
            nodes << { type: :partial, name: token[1][:value] }
          when :layout
            tag_name = token[1][:value]
            nodes << { type: :layout, name: tag_name, children: build_tree(tokens, tag_name) }
          when :block_open
            tag_name = token[1][:value]
            nodes << { type: :block, name: tag_name, children: build_tree(tokens, tag_name) }
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
