# frozen-string-literal: true
module Mobility
  module Plugins
=begin

See ActiveRecord::Query plugin.

=end
    module Sequel
      module Query
        class << self
          def apply(attributes)
            attributes.model_class.class_eval do
              extend QueryMethod
              singleton_class.send :alias_method, Mobility.query_method, :__mobility_query_dataset__
            end
          end
        end

        module QueryMethod
          def __mobility_query_dataset__(locale: Mobility.locale, &block)
            if block_given?
              VirtualRow.build_query(self, locale, &block)
            else
              dataset.with_extend(QueryExtension)
            end
          end
        end

        # Internal class to create a "clean room" for manipulating translated
        # attribute nodes in an instance-eval'ed block. Inspired by Sequel's
        # (much more sophisticated) virtual rows.
        class VirtualRow < BasicObject
          attr_reader :__backends

          def initialize(model_class, locale)
            @model_class, @locale, @__backends = model_class, locale, []
          end

          def method_missing(m, *)
            if @model_class.mobility_attribute?(m)
              @__backends |= [@model_class.mobility_backend_class(m)]
              @model_class.mobility_backend_class(m).build_op(m.to_s, @locale)
            elsif @model_class.columns.include?(m.to_s)
              ::Sequel::SQL::QualifiedIdentifier.new(@model_class.table_name, m)
            else
              super
            end
          end

          class << self
            def build_query(klass, locale, &block)
              row = new(klass, locale)
              query = block.arity.zero? ? row.instance_eval(&block) : block.call(row)

              if ::Sequel::Dataset === query
                predicates = query.opts[:where]
                prepare_datasets(query, row.__backends, locale, predicates)
              else
                prepare_datasets(klass.dataset, row.__backends, locale, query).where(query)
              end
            end

            private

            def prepare_datasets(dataset, backends, locale, predicates)
              backends.inject(dataset) { |ds, b| b.prepare_dataset(ds, predicates, locale) }
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
              return yield unless Hash === query_conds.first

              cond = query_conds.first.dup
              locale = cond.delete(:locale) || Mobility.locale

              _build(dataset, cond, locale, query_method, &block)
            end

            private

            def _build(dataset, cond, locale, query_method)
              keys, predicates = cond.keys, []
              model = dataset.model

              query_map = model.mobility_modules.inject(IDENTITY) do |qm, mod|
                i18n_keys = mod.names.map(&:to_sym) & keys
                next qm if i18n_keys.empty?

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

            def build_predicate(op, values)
              vals = values.is_a?(Array) ? values.uniq: [values]
              vals = vals.first if vals.size == 1
              op =~ vals
            end
          end
        end
      end
    end
  end
end
