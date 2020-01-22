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
            attributes.backend_class.include self
          end

          def attribute_alias(attribute, locale = Mobility.locale)
            "__mobility_%s_%s__"  % [attribute, ::Mobility.normalize_locale(locale)]
          end
        end

        # @note We use +instance_variable_get+ here to get the +AttributeSet+
        #   rather than the hash of attributes. Getting the full hash of
        #   attributes is a performance hit and better to avoid if unnecessary.
        # TODO: Improve this.
        def read(locale, **)
          if (model_attributes_defined? &&
              model_attributes.key?(alias_ = Query.attribute_alias(attribute, locale)))
            model_attributes[alias_].value
          else
            super
          end
        end

        private

        def model_attributes_defined?
          model.instance_variable_defined?(:@attributes)
        end

        def model_attributes
          model.instance_variable_get(:@attributes)
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
            if @model_class.mobility_attribute?(m)
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

          def order(opts, *rest)
            case opts
            when Symbol, String
              @klass.mobility_attribute?(opts) ? order({ opts => :asc }, *rest) : super
            when Hash
              i18n_keys, keys = opts.keys.partition(&@klass.method(:mobility_attribute?))
              return super if i18n_keys.empty?

              base = keys.empty? ? self : super(opts.slice(keys))

              i18n_keys.inject(base) do |query, key|
                backend_class = @klass.mobility_backend_class(key)
                dir, node = opts[key], backend_node(key)
                backend_class.apply_scope(query, node).order(node.send(dir.downcase))
              end
            else
              super
            end
          end

          if ::ActiveRecord::VERSION::STRING >= '5.0'
            %w[pluck group select].each do |method_name|
              define_method method_name do |*attrs, &block|
                return super(&block) if (method_name == 'select' && block.present?)

                return super(*attrs) unless attrs.any?(&@klass.method(:mobility_attribute?))

                keys = attrs.dup

                base = keys.each_with_index.inject(self) do |query, (key, index)|
                  next query unless @klass.mobility_attribute?(key)
                  keys[index] = backend_node(key)
                  if method_name == "select"
                    keys[index] = keys[index]
                      .as(::Mobility::Plugins::ActiveRecord::Query.attribute_alias(key.to_s))
                  end
                  @klass.mobility_backend_class(key).apply_scope(query, backend_node(key))
                end

                base.public_send(method_name, *keys)
              end
            end
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
            IDENTITY = ->(x) { x }.freeze

            class << self
              def build(scope, where_opts, invert: false, &block)
                return yield unless Hash === where_opts

                opts = where_opts.with_indifferent_access
                locale = opts.delete(:locale) || Mobility.locale

                _build(scope, opts, locale, invert, &block)
              end

              private

              # Builds a translated relation for a given opts hash and optional
              # invert boolean.
              def _build(scope, opts, locale, invert)
                return yield unless scope.respond_to?(:mobility_modules)

                keys, predicates = opts.keys.map(&:to_s), []

                query_map = scope.mobility_modules.inject(IDENTITY) do |qm, mod|
                  i18n_keys = mod.names & keys
                  next qm if i18n_keys.empty?

                  mod_predicates = i18n_keys.map do |key|
                    build_predicate(scope.backend_node(key.to_sym, locale), opts.delete(key))
                  end
                  invert_predicates!(mod_predicates) if invert
                  predicates += mod_predicates

                  ->(r) { mod.backend_class.apply_scope(qm[r], mod_predicates, locale, invert: invert) }
                end

                return yield if query_map == IDENTITY

                relation = opts.empty? ? scope : yield(opts)
                query_map[relation.where(predicates.inject(&:and))]
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

              def invert_predicates!(predicates)
                predicates.map!(&method(:invert_predicate))
              end

              # Adapted from AR::Relation::WhereClause#invert_predicate
              def invert_predicate(predicate)
                case predicate
                when ::Arel::Nodes::In
                  ::Arel::Nodes::NotIn.new(predicate.left, predicate.right)
                when ::Arel::Nodes::Equality
                  ::Arel::Nodes::NotEqual.new(predicate.left, predicate.right)
                else
                  ::Arel::Nodes::Not.new(predicate)
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
