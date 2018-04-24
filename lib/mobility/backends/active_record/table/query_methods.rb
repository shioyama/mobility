# frozen_string_literal: true
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    module ActiveRecord
      class Table::QueryMethods < QueryMethods
        def initialize(attributes, association_name: nil, model_class: nil, subclass_name: nil, **options)
          super

          @association_name  = association_name
          @translation_class = translation_class = model_class.const_get(subclass_name)

          define_join_method(association_name, translation_class, **options)
          define_query_methods(association_name, translation_class, **options)
        end

        def extended(relation)
          super
          association_name  = @association_name
          translation_class = @translation_class
          q                 = self

          mod = Module.new do
            define_method :not do |opts, *rest|
              if i18n_keys = q.extract_attributes(opts)
                opts = opts.with_indifferent_access
                i18n_keys.each do |attr|
                  opts["#{translation_class.table_name}.#{attr}"] = q.collapse opts.delete(attr)
                end
                super(opts, *rest).send("join_#{association_name}")
              else
                super(opts, *rest)
              end
            end
          end
          relation.mobility_where_chain.include(mod)
        end

        private

        def define_join_method(association_name, translation_class, foreign_key: nil, table_name: nil, **)
          define_method :"join_#{association_name}" do |**options|
            if join = joins_values.find { |v| (Arel::Nodes::Join === v) && (v.left.name == table_name.to_s) }
              return self if (options[:outer_join] || Arel::Nodes::InnerJoin === join)
              self.joins_values = joins_values - [join]
            end
            t = translation_class.arel_table
            m = arel_table
            join_type = options[:outer_join] ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
            joins(m.join(t, join_type).
                  on(t[foreign_key].eq(m[:id]).
                     and(t[:locale].eq(Mobility.locale))).join_sources)
          end
        end

        def define_query_methods(association_name, translation_class, **)
          q = self

          # Note that Mobility will try to use inner/outer joins appropriate to the query,
          # so for example:
          #
          # Article.where(title: nil, content: nil)          #=> OUTER JOIN (all nils)
          # Article.where(title: "foo", content: nil)        #=> INNER JOIN (one non-nil)
          #
          # In the first case, if we are in (say) the "en" locale, then we should match articles
          # that have *no* article_translations with English locales (since no translation is
          # equivalent to a nil value). If we used an inner join in the first case, an article
          # with no English translations would be filtered out, so we use an outer join.
          #
          # When deciding whether to use an outer or inner join, array-valued
          # conditions are treated as nil if they have any values.
          #
          # Article.where(title: nil, content: ["foo", nil])                  #=> OUTER JOIN (all nil or array with nil)
          # Article.where(title: "foo", content: ["foo", nil])                #=> INNER JOIN (one non-nil)
          # Article.where(title: ["foo", "bar"], content: ["foo", nil])       #=> INNER JOIN (one non-nil array)
          #
          # The logic also applies when a query has more than one where clause.
          #
          # Article.where(title: nil).where(content: nil)    #=> OUTER JOIN (all nils)
          # Article.where(title: nil).where(content: "foo")  #=> INNER JOIN (one non-nil)
          # Article.where(title: "foo").where(content: nil)  #=> INNER JOIN (one non-nil)
          #
          define_method :where! do |opts, *rest|
            if i18n_keys = q.extract_attributes(opts)
              opts = opts.with_indifferent_access
              options = {
                # We only need an OUTER JOIN if every value is either nil, or an
                # array with at least one nil value.
                outer_join: opts.values_at(*i18n_keys).compact.all? { |v| ![*v].all? }
              }
              i18n_keys.each do |attr|
                opts["#{translation_class.table_name}.#{attr}"] = q.collapse opts.delete(attr)
              end
              super(opts, *rest).send("join_#{association_name}", options)
            else
              super(opts, *rest)
            end
          end
        end
      end
      Table.private_constant :QueryMethods
    end
  end
end
