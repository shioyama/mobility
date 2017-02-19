module Mobility
  module Backend
    autoload :ActiveModel,  'mobility/backend/active_model'
    autoload :ActiveRecord, 'mobility/backend/active_record'
    autoload :Cache,        'mobility/backend/cache'
    autoload :Column,       'mobility/backend/column'
    autoload :Dirty,        'mobility/backend/dirty'
    autoload :Fallbacks,    'mobility/backend/fallbacks'
    autoload :Hstore,       'mobility/backend/hstore'
    autoload :Jsonb,        'mobility/backend/jsonb'
    autoload :KeyValue,     'mobility/backend/key_value'
    autoload :Null,         'mobility/backend/null'
    autoload :OrmDelegator, 'mobility/backend/orm_delegator'
    autoload :Sequel,       'mobility/backend/sequel'
    autoload :Serialized,   'mobility/backend/serialized'
    autoload :Table,        'mobility/backend/table'

    attr_reader :attribute, :model, :options

    def initialize(model, attribute, **options)
      @model = model
      @attribute = attribute
      @options = options
      fallbacks = options[:fallbacks]
      @fallbacks = I18n::Locale::Fallbacks.new(fallbacks) if fallbacks.is_a?(Hash)
    end

    def self.included(base)
      base.extend(Setup)
    end

    def self.method_name(attribute)
      "#{attribute}_backend"
    end

    module Setup
      def setup &block
        if @setup_block
          setup_block = @setup_block
          @setup_block = lambda do |*args|
            class_exec(*args, &setup_block)
            class_exec(*args, &block)
          end
        else
          @setup_block = block
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@setup_block, @setup_block)
      end

      def setup_model(model_class, attributes, **options)
        return unless setup_block = @setup_block
        model_class.class_exec(attributes, options, &setup_block)
      end

      def for(_)
        self
      end
    end
  end
end
