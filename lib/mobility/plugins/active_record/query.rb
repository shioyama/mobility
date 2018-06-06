# frozen-string-literal: true
module Mobility
  module Plugins
=begin

Adds a scope which enables querying on translated attributes using +where+ and
+not+ as if they were normal attributes. Under the hood, this plugin uses the
generic +build_node+ and +apply_scope+ methods implemented in each backend
class to build ActiveRecord queries from Arel nodes. The plugin also adds
+find_by_<attribute>+ shortcuts for translated attributes.

The query scope applies to all translated attributes once the plugin has been
enabled for any one attribute on the model.

=end
    module ActiveRecord
      module Query
        class << self
          def apply(attributes)
            attributes.model_class.class_eval do
              extend QueryMethod
              extend FindByMethods.new(*attributes.names)
              singleton_class.send :alias_method, Mobility.query_method, :__mobility_query_scope__
            end
          end
        end

        module QueryMethod
          def __mobility_query_scope__(locale: Mobility.locale, &block)
            if block_given?
              VirtualRow.build_query(self, locale, &block)
            else
              all.extending(QueryExtension)
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
            if @model_class.mobility_attributes.include?(m.to_s)
              @__backends |= [@model_class.mobility_backend_class(m)]
              @model_class.mobility_backend_class(m).build_node(m, @locale)
            elsif @model_class.column_names.include?(m.to_s)
              @model_class.arel_table[m]
            else
              super
            end
          end

          class << self
            def build_query(klass, locale, &block)
              row = new(klass, locale)
              query = block.arity.zero? ? row.instance_eval(&block) : block.call(row)

              if ::ActiveRecord::Relation === query
                predicates = query.arel.constraints
                apply_scopes(klass.all, row.__backends, locale, predicates).merge(query)
              else
                apply_scopes(klass.all, row.__backends, locale, query).where(query)
              end
            end

            private

            def apply_scopes(scope, backends, locale, predicates)
              backends.inject(scope) { |r, b| b.apply_scope(r, predicates, locale) }
            end
          end
        end
        private_constant :QueryMethod, :VirtualRow

        module QueryExtension
          def where!(opts, *rest)
            QueryBuilder.build(self, opts) do |untranslated_opts|
              untranslated_opts ? super(untranslated_opts, *rest) : super
            end
          end

          def where(opts = :chain, *rest)
            opts == :chain ? WhereChain.new(spawn) : super
          end

          # Return backend node for attribute name.
          # @param [Symbol,String] name Name of attribute
          # @param [Symbol] locale Locale
          # @return [Arel::Node] Arel node for this attribute in given locale
          def backend_node(name, locale = Mobility.locale)
            @klass.mobility_backend_class(name)[name, locale]
          end

          class WhereChain < ::ActiveRecord::QueryMethods::WhereChain
            def not(opts, *rest)
              QueryBuilder.build(@scope, opts, invert: true) do |untranslated_opts|
                untranslated_opts ? super(untranslated_opts, *rest) : super
              end
            end
          end

          module QueryBuilder
            class << self
              def build(scope, where_opts, invert: false)
                return yield unless Hash === where_opts

                opts = where_opts.with_indifferent_access
                locale = opts.delete(:locale) || Mobility.locale

                maps = build_maps!(scope, opts, locale, invert: invert)
                return yield if maps.empty?

                base = opts.empty? ? scope : yield(opts)
                maps.inject(base) { |rel, map| map[rel] }
              end

              private

              def build_maps!(scope, opts, locale, invert:)
                keys = opts.keys.map(&:to_s)

                scope.mobility_modules.map { |mod|
                  next if (i18n_keys = mod.names & keys).empty?

                  predicates = i18n_keys.map do |key|
                    build_predicate(scope.backend_node(key.to_sym, locale), opts.delete(key))
                  end

                  ->(relation) do
                    relation = mod.backend_class.apply_scope(relation, predicates, locale, invert: invert)
                    predicates = predicates.map(&method(:invert_predicate)) if invert
                    relation.where(predicates.inject(&:and))
                  end
                }.compact
              end

              def build_predicate(node, values)
                nils, vals = partition_values(values)

                return node.eq(nil) if vals.empty?

                predicate = vals.length == 1 ? node.eq(vals.first) : node.in(vals)
                predicate = predicate.or(node.eq(nil)) unless nils.empty?
                predicate
              end

              def partition_values(values)
                Array.wrap(values).uniq.partition(&:nil?)
              end

              # Adapted from AR::Relation::WhereClause#invert_predicate
              def invert_predicate(node)
                case node
                when ::Arel::Nodes::In
                  ::Arel::Nodes::NotIn.new(node.left, node.right)
                when ::Arel::Nodes::Equality
                  ::Arel::Nodes::NotEqual.new(node.left, node.right)
                else
                  ::Arel::Nodes::Not.new(node)
                end
              end
            end
          end

          private_constant :WhereChain, :QueryBuilder
        end

        class FindByMethods < Module
          def initialize(*attributes)
            attributes.each do |attribute|
              module_eval <<-EOM, __FILE__, __LINE__ + 1
              def find_by_#{attribute}(value)
                find_by(#{attribute}: value)
              end
              EOM
            end
          end
        end

        private_constant :QueryExtension, :FindByMethods
      end
    end
  end
end
