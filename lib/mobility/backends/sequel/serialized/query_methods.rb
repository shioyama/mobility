# frozen_string_literal: true
require "mobility/backends/sequel/query_methods"

module Mobility
  module Backends
    class Sequel::Serialized::QueryMethods < Sequel::QueryMethods
      include Serialized

      def initialize(attributes, _)
        super
        q = self

        define_method :where do |*cond, &block|
          q.check_opts(cond.first) || super(*cond, &block)
        end
      end
    end
  end
end
