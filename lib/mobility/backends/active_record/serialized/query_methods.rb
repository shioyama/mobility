# frozen_string_literal: true
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    module ActiveRecord
      class Serialized::QueryMethods < QueryMethods
        include Backends::Serialized

        def initialize(attributes, _)
          super
          q = self

          define_method :where! do |opts, *rest|
            q.check_opts(opts) || super(opts, *rest)
          end
        end

        def extended(relation)
          super
          q = self

          mod = Module.new do
            define_method :not do |opts, *rest|
              q.check_opts(opts) || super(opts, *rest)
            end
          end
          relation.mobility_where_chain.include(mod)
        end
      end
      Serialized.private_constant :QueryMethods
    end
  end
end
