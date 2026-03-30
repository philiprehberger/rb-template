# frozen_string_literal: true

module Philiprehberger
  class Template
    class Renderer
      def initialize(tree, context, partials: {}, layouts: {}, strict: false)
        @tree = tree
        @context = context
        @partials = partials
        @layouts = layouts
        @strict = strict
      end

      def render
        render_nodes(@tree)
      end

      private

      def render_nodes(nodes)
        nodes.map { |node| render_node(node) }.join
      end

      def render_node(node)
        case node[:type]
        when :text              then node[:value]
        when :variable          then render_variable(node)
        when :filtered_variable then render_filtered(node)
        when :section           then render_section(node)
        when :inverted          then render_inverted(node)
        when :partial           then render_partial(node)
        when :layout            then render_layout(node)
        when :block             then render_block(node)
        end
      end

      def render_variable(node)
        value = @context.lookup(node[:name])
        if value.nil? && @strict && !@context.defined?(node[:name])
          raise UndefinedVariableError, node[:name]
        end

        value.to_s
      end

      def render_filtered(node)
        value = @context.lookup(node[:name])
        if value.nil? && @strict && !@context.defined?(node[:name])
          raise UndefinedVariableError, node[:name]
        end

        node[:filters].reduce(value) do |val, filter_info|
          filter = Filters.resolve(filter_info[:name])
          if filter
            if filter_info[:arg]
              filter.call(val, filter_info[:arg])
            else
              filter.call(val)
            end
          else
            val.to_s
          end
        end.to_s
      end

      def render_section(node)
        value = @context.lookup(node[:name])

        # Lambda support: if value is callable, pass raw content
        if value.respond_to?(:call)
          raw = node[:raw_content] || ''
          result = value.call(raw)
          return result.to_s
        end

        return '' unless truthy?(value)
        return render_array(node, value) if value.is_a?(Array)

        @context.push(value.is_a?(Hash) ? value : {})
        result = render_nodes(node[:children])
        @context.pop
        result
      end

      def render_inverted(node)
        value = @context.lookup(node[:name])
        truthy?(value) ? '' : render_nodes(node[:children])
      end

      def render_array(node, items)
        items.map do |item|
          @context.push(item.is_a?(Hash) ? item : {})
          result = render_nodes(node[:children])
          @context.pop
          result
        end.join
      end

      def render_partial(node)
        partial_source = @partials[node[:name]] || @partials[node[:name].to_sym]
        return '' unless partial_source

        partial_tree = Parser.new(partial_source).parse
        render_nodes(partial_tree)
      end

      def render_layout(node)
        layout_source = @layouts[node[:name]] || @layouts[node[:name].to_sym]
        return render_nodes(node[:children]) unless layout_source

        # Collect block overrides from the child content
        block_overrides = {}
        node[:children].each do |child|
          block_overrides[child[:name]] = child if child[:type] == :block
        end

        layout_tree = Parser.new(layout_source).parse
        render_layout_tree(layout_tree, block_overrides)
      end

      def render_layout_tree(nodes, block_overrides)
        nodes.map do |n|
          case n[:type]
          when :block
            if block_overrides[n[:name]]
              render_nodes(block_overrides[n[:name]][:children])
            else
              render_nodes(n[:children])
            end
          when :section
            value = @context.lookup(n[:name])
            if value.respond_to?(:call)
              raw = n[:raw_content] || ''
              value.call(raw).to_s
            elsif truthy?(value)
              if value.is_a?(Array)
                render_array(n, value)
              else
                @context.push(value.is_a?(Hash) ? value : {})
                result = render_layout_tree(n[:children], block_overrides)
                @context.pop
                result
              end
            else
              ''
            end
          when :inverted
            value = @context.lookup(n[:name])
            truthy?(value) ? '' : render_layout_tree(n[:children], block_overrides)
          else
            render_node(n)
          end
        end.join
      end

      def render_block(node)
        # Standalone block (not inside a layout) renders its children as default
        render_nodes(node[:children])
      end

      def truthy?(value)
        return false if value.nil? || value == false
        return false if value.is_a?(Array) && value.empty?

        true
      end
    end
  end
end
