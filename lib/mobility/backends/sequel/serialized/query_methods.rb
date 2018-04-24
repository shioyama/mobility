# frozen_string_literal: true
require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    module Sequel
      class Serialized::QueryMethods < QueryMethods
        include Backends::Serialized

        def initialize(attributes, _)
          super
          q = self

          define_method :where do |*cond, &block|
            q.check_opts(cond.first) || super(*cond, &block)
          end
        end
      end
      Serialized.private_constant :QueryMethods
    end
  end
end
