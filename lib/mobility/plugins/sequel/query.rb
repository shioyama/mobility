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
          def __mobility_query_dataset__(*)
            dataset.with_extend(QueryExtension)
          end
        end
        private_constant :QueryMethod

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
