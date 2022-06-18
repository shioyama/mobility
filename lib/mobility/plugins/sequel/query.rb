# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Supports querying on Sequel model translated attributes. Similar API to the
ActiveRecord query plugin.

=end
    module Sequel
      module Query
        extend Plugin

        requires :query, include: false

        included_hook do |klass, _|
          plugin = self
          if options[:query]
            raise MissingBackend, "backend required for Query plugin" unless backend_class

            klass.class_eval do
              extend QueryMethod
              singleton_class.define_method(plugin.query_method) do |locale: Mobility.locale, &block|
                Query.build_query(self, locale, &block)
              end
            end
          end
        end

        class << self
          def build_query(klass, locale = Mobility.locale, &block)
            if block_given?
              VirtualRow.build_query(klass, locale, &block)
            else
              klass.dataset.with_extend(QueryExtension)
            end
          end
        end

        module QueryMethod
          def __mobility_query_dataset__(locale: Mobility.locale, &block)
            warn '__mobility_query_dataset__ is an internal method and will be deprecated in the next release.'
            Query.build_query(self, locale, &block)
          end
        end

        # Internal class to create a "clean room" for manipulating translated
        # attribute nodes in an instance-eval'ed block. Inspired by Sequel's
        # (much more sophisticated) virtual rows.
        class VirtualRow < BasicObject
          attr_reader :backends, :locales

          def initialize(model_class, global_locale)
            @model_class, @global_locale, @backends, @locales = model_class, global_locale, [], []
          end

          def method_missing(m, *args)
            if @model_class.mobility_attribute?(m)
              @backends |= [@model_class.mobility_backend_class(m)]
              ::Mobility.validate_locale!(args[0]) if args[0]
              locale = args[0] || @global_locale
              @locales |= [locale]
              @model_class.mobility_backend_class(m).build_op(m.to_s, locale)
            elsif @model_class.columns.include?(m)
              ::Sequel::SQL::QualifiedIdentifier.new(@model_class.table_name, m)
            else
              super
            end
          end

          class << self
            def build_query(klass, locale, &block)
              ::Mobility.validate_locale!(locale)

              row = new(klass, locale)
              query = block.arity.zero? ? row.instance_eval(&block) : block.call(row)

              if ::Sequel::Dataset === query
                predicates = query.opts[:where]
                prepare_datasets(query, row.backends, row.locales, predicates)
              else
                prepare_datasets(klass.dataset, row.backends, row.locales, query).where(query)
              end
            end

            private

            def prepare_datasets(dataset, backends, locales, predicates)
              backends.inject(dataset) do |dataset_, b|
                locales.inject(dataset_) do |ds, locale|
                  b.prepare_dataset(ds, predicates, locale)
                end
              end
            end
          end
        end
        private_constant :QueryMethod, :VirtualRow

        module QueryExtension
          %w[exclude or where].each do |method_name|
            module_eval <<-EOM, __FILE__, __LINE__ + 1
            def #{method_name}(*conds, &block)
              QueryBuilder.build(self, #{method_name.inspect}, conds) do |untranslated_conds|
                untranslated_conds ? super(untranslated_conds, &block) : super
              end
            end
            EOM
          end

          # Return backend node for attribute name.
          # @param [Symbol,String] name Name of attribute
          # @param [Symbol] locale Locale
          # @return [Arel::Node] Arel node for this attribute in given locale
          def backend_op(name, locale = Mobility.locale)
            model.mobility_backend_class(name)[name, locale]
          end
        end

        module QueryBuilder
          IDENTITY = ->(x) { x }.freeze

          class << self
            def build(dataset, query_method, query_conds, &block)
              return yield unless ::Hash === query_conds.first

              cond = query_conds.first.dup
              locale = cond.delete(:locale) || Mobility.locale

              _build(dataset, cond, locale, query_method, &block)
            end

            private

            def _build(dataset, cond, locale, query_method)
              keys, predicates = cond.keys, []
              model = dataset.model

              used_keys = []

              query_map = attribute_modules(model).inject(IDENTITY) do |qm, mod|
                i18n_keys = mod.names.map(&:to_sym) & keys - used_keys
                next qm if i18n_keys.empty?

                used_keys += i18n_keys
                mod_predicates = i18n_keys.map do |key|
                  build_predicate(dataset.backend_op(key, locale), cond.delete(key))
                end
                predicates += mod_predicates

                ->(ds) { mod.backend_class.prepare_dataset(qm[ds], mod_predicates, locale) }
              end

              return yield if query_map == IDENTITY

              predicates = ::Sequel.&(*predicates, cond) unless cond.empty?
              query_map[dataset.public_send(query_method, ::Sequel.&(*predicates))]
            end

            def attribute_modules(model)
              model.ancestors.grep(::Mobility::Translations)
            end

            def build_predicate(op, values)
              vals = values.is_a?(Array) ? values.uniq: [values]
              vals = vals.first if vals.size == 1
              op =~ vals
            end
          end
        end
      end

      class MissingBackend < Mobility::Error; end
    end

    register_plugin(:sequel_query, Sequel::Query)
  end
end
