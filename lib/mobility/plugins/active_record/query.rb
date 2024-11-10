# frozen-string-literal: true
require "active_record/relation"

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
        extend Plugin

        requires :query, include: false

        included_hook do |klass, backend_class|
          plugin = self
          if options[:query]
            raise MissingBackend, "backend required for Query plugin" unless backend_class

            klass.class_eval do
              extend QueryMethod
              extend FindByMethods.new(*plugin.names)
              singleton_class.define_method(plugin.query_method) do |locale: Mobility.locale, &block|
                Query.build_query(self, locale, &block)
              end
            end
            backend_class.include BackendMethods
          end
        end

        class << self
          def attribute_alias(attribute, locale = Mobility.locale)
            "__mobility_%s_%s__"  % [attribute, ::Mobility.normalize_locale(locale)]
          end

          def build_query(klass, locale = Mobility.locale, &block)
            if block_given?
              VirtualRow.build_query(klass, locale, &block)
            else
              klass.all.extending(QueryExtension)
            end
          end
        end

        module BackendMethods
          # @note We use +instance_variable_get+ here to get the +AttributeSet+
          #   rather than the hash of attributes. Getting the full hash of
          #   attributes is a performance hit and better to avoid if unnecessary.
          # TODO: Improve this.
          def read(locale, **)
            if model.instance_variable_defined?(:@attributes) &&
                (model_attributes = model.instance_variable_get(:@attributes)).key?(alias_ = Query.attribute_alias(attribute, locale))
              model_attributes[alias_].value
            else
              super
            end
          end
        end

        module QueryMethod
          def __mobility_query_scope__(locale: Mobility.locale, &block)
            warn '__mobility_query_scope__ is an internal method and will be deprecated in the next release.'
            Query.build_query(self, locale, &block)
          end
        end

        # Creates a "clean room" for manipulating translated attribute nodes in
        # an instance-eval'ed block. Inspired by Sequel's (much more
        # sophisticated) virtual rows.
        class VirtualRow < BasicObject
          attr_reader :backends, :locales

          def initialize(klass, global_locale)
            @klass, @global_locale, @locales, @backends = klass, global_locale, [], []
          end

          def method_missing(m, *args)
            if @klass.mobility_attribute?(m)
              @backends |= [@klass.mobility_backend_class(m)]
              ::Mobility.validate_locale!(args[0]) if args[0]
              locale = args[0] || @global_locale
              @locales |= [locale]
              @klass.mobility_backend_class(m).build_node(m, locale)
            elsif @klass.column_names.include?(m.to_s)
              @klass.arel_table[m]
            else
              super
            end
          end

          class << self
            def build_query(klass, locale, &block)
              ::Mobility.validate_locale!(locale)

              row = new(klass, locale)
              query = block.arity.zero? ? row.instance_eval(&block) : block.call(row)

              if ::ActiveRecord::Relation === query
                predicates = query.arel.constraints
                apply_scopes(klass.all, row.backends, row.locales, predicates).merge(query)
              else
                apply_scopes(klass.all, row.backends, row.locales, query).where(query)
              end
            end

            private

            def apply_scopes(scope, backends, locales, predicates)
              backends.inject(scope) do |scope_, b|
                locales.inject(scope_) do |r, locale|
                  b.apply_scope(r, predicates, locale)
                end
              end
            end
          end
        end
        private_constant :QueryMethod

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
            return super unless klass.respond_to?(:mobility_attribute?)

            case opts
            when Symbol, String
              klass.mobility_attribute?(opts) ? order({ opts => :asc }, *rest) : super
            when ::Hash
              i18n_keys, keys = opts.keys.partition(&klass.method(:mobility_attribute?))
              return super if i18n_keys.empty?

              base = keys.empty? ? self : super(opts.slice(keys))

              i18n_keys.inject(base) do |query, key|
                backend_class = klass.mobility_backend_class(key)
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
                return super(*attrs, &block) if (method_name == 'select' && block.present?)

                return super(*attrs, &block) unless klass.respond_to?(:mobility_attribute?)

                return super(*attrs, &block) unless attrs.any?(&klass.method(:mobility_attribute?))

                keys = attrs.dup

                base = keys.each_with_index.inject(self) do |query, (key, index)|
                  next query unless klass.mobility_attribute?(key)
                  keys[index] = backend_node(key)
                  if method_name == "select" && query.order_values.any?
                    keys[index] = keys[index]
                      .as(::Mobility::Plugins::ActiveRecord::Query.attribute_alias(key.to_s))
                  end
                  klass.mobility_backend_class(key).apply_scope(query, backend_node(key))
                end

                base.public_send(method_name, *keys, &block)
              end
            end
          end

          # Return backend node for attribute name.
          # @param [Symbol,String] name Name of attribute
          # @param [Symbol] locale Locale
          # @return [Arel::Node] Arel node for this attribute in given locale
          def backend_node(name, locale = Mobility.locale)
            klass.mobility_backend_class(name)[name, locale]
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
                return yield unless ::Hash === where_opts

                opts = where_opts.with_indifferent_access
                locale = opts.delete(:locale) || Mobility.locale

                _build(scope, opts, locale, invert, &block)
              end

              private

              # Builds a translated relation for a given opts hash and optional
              # invert boolean.
              def _build(scope, opts, locale, invert)
                return yield if (mods = translation_modules(scope)).empty?

                keys, predicates = opts.keys.map(&:to_s), []

                used_keys = []

                query_map = mods.inject(IDENTITY) do |qm, mod|
                  i18n_keys = mod.names & keys - used_keys
                  next qm if i18n_keys.empty?

                  used_keys += i18n_keys
                  mod_predicates = i18n_keys.map do |key|
                    build_predicate(scope.backend_node(key.to_sym, locale), opts.delete(key))
                  end
                  invert_predicates!(mod_predicates) if invert
                  predicates += mod_predicates

                  ->(r) { mod.backend_class.apply_scope(qm[r], mod_predicates, locale, invert: invert) }
                end

                return yield if query_map == IDENTITY

                relation = opts.empty? ? scope : yield(opts)
                query_map[relation.where(predicates.inject(:and))]
              end

              def translation_modules(scope)
                scope.model.ancestors.grep(::Mobility::Translations)
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

        private_constant :FindByMethods
      end

      class MissingBackend < Mobility::Error; end
    end

    register_plugin(:active_record_query, ActiveRecord::Query)
  end
end
