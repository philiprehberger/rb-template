# frozen_string_literal: true

require 'cgi'

module Philiprehberger
  class Template
    module Filters
      BUILT_IN = {
        'upcase' => ->(val) { val.to_s.upcase },
        'downcase' => ->(val) { val.to_s.downcase },
        'strip' => ->(val) { val.to_s.strip },
        'escape' => ->(val) { CGI.escapeHTML(val.to_s) },
        'capitalize' => ->(val) { val.to_s.capitalize },
        'reverse' => ->(val) { val.to_s.reverse },
        'length' => ->(val) { val.respond_to?(:length) ? val.length.to_s : val.to_s.length.to_s },
        'default' => ->(val, arg = '') { val.nil? || val.to_s.empty? ? arg : val.to_s }
      }.freeze

      @custom = {}

      class << self
        def register(name, callable)
          @custom[name.to_s] = callable
        end

        def resolve(name)
          @custom[name.to_s] || BUILT_IN[name.to_s]
        end

        def reset_custom!
          @custom = {}
        end
      end
    end
  end
end
