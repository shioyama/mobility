# frozen_string_literal: true
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    module ActiveRecord
      class Column::QueryMethods < QueryMethods
        def initialize(attributes, _)
          super
          q = self

          define_method :where! do |opts, *rest|
            super(q.convert_opts(opts), *rest)
          end
        end

        def extended(relation)
          super
          q = self

          mod = Module.new do
            define_method :not do |opts, *rest|
              super(q.convert_opts(opts), *rest)
            end
          end
          relation.mobility_where_chain.include(mod)
        end

        def convert_opts(opts)
          if i18n_keys = extract_attributes(opts)
            opts = opts.with_indifferent_access
            i18n_keys.each do |attr|
              opts[Backends::Column.column_name_for(attr)] = collapse opts.delete(attr)
            end
          end
          opts
        end
      end
      Column.private_constant :QueryMethods
    end
  end
end
