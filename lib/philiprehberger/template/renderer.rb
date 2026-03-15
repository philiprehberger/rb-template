# frozen_string_literal: true

module Philiprehberger
  class Template
    class Renderer
      def initialize(tree, context)
        @tree = tree
        @context = context
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
        when :text     then node[:value]
        when :variable then @context.lookup(node[:name]).to_s
        when :section  then render_section(node)
        when :inverted then render_inverted(node)
        end
      end

      def render_section(node)
        value = @context.lookup(node[:name])
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

      def truthy?(value)
        return false if value.nil? || value == false
        return false if value.is_a?(Array) && value.empty?

        true
      end
    end
  end
end
