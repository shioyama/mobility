# frozen_string_literal: true
require "mobility/backends/active_record/query_methods"

module Mobility
  module Backends
    class ActiveRecord::Table::QueryMethods < ActiveRecord::QueryMethods
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
              locale = opts.delete(:locale) || Mobility.locale
              i18n_keys.each do |attr|
                opts["#{translation_class.table_name}.#{attr}"] = q.collapse opts.delete(attr)
              end
              super(opts, *rest).send("join_#{association_name}", locale: locale)
            else
              super(opts, *rest)
            end
          end
        end
        relation.mobility_where_chain.include(mod)
      end

      private

      def define_join_method(association_name, translation_class, foreign_key: nil, table_name: nil, **)
        define_method :"join_#{association_name}" do |locale:, outer_join: false, **options|
          return self if joins_values.any? { |v| v.is_a?(Arel::Nodes::Join) && (v.left.name == table_name.to_s) }
          t = translation_class.arel_table
          m = arel_table
          join_type = outer_join ? Arel::Nodes::OuterJoin : Arel::Nodes::InnerJoin
          matches_locale = locale.is_a?(Array) ? t[:locale].in(locale) : t[:locale].eq(locale)
          joins(m.join(t, join_type).on(t[foreign_key].eq(m[:id]).and(matches_locale)).join_sources)
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
        # Article.where(title: nil, content: ["foo", nil])            #=> OUTER JOIN (all nil or array with nil)
        # Article.where(title: "foo", content: ["foo", nil])          #=> INNER JOIN (one non-nil)
        # Article.where(title: ["foo", "bar"], content: ["foo", nil]) #=> INNER JOIN (one non-nil array)
        #
        # Note that if you call `where` multiple times, you may end up with an
        # outer join when a (faster) inner join would have worked fine:
        #
        # Article.where(title: nil).where(content: "foo")          #=> OUTER JOIN
        # Article.where(title: [nil, "foo"]).where(content: "foo") #=> OUTER JOIN
        #
        # In this case, we are searching for a match on the article_translations table
        # which has a NULL title and a content equal to "foo". Since we need a positive
        # match for content, there must be an English translation on the article, thus
        # we can use an inner join. However, Mobility will use an outer join since we don't
        # want to modify the existing relation which has already been joined.
        #
        # To avoid this problem, simply make sure to either order your queries to place nil
        # values last, or include all queried attributes in a single `where`:
        #
        # Article.where(title: nil, content: "foo") #=> INNER JOIN
        #
        define_method :where! do |opts, *rest|
          if i18n_keys = q.extract_attributes(opts)
            opts = opts.with_indifferent_access
            options = {
              # We only need an OUTER JOIN if every value is either nil, or an
              # array with at least one nil value.
              outer_join: opts.values_at(*i18n_keys).compact.all? { |v| !Array(v).all? },
              locale: opts.delete(:locale) || Mobility.locale
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
  end
end
