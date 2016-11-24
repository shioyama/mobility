module Mobility
  module Backend
    module Base
      attr_reader :attribute, :model, :options

      def initialize(model, attribute, options = {})
        @model = model
        @attribute = attribute
        @options = options
        fallbacks = options[:fallbacks]
        @fallbacks = I18n::Locale::Fallbacks.new(fallbacks) if fallbacks.is_a?(Hash)
      end

      def self.included(base)
        base.extend(Setup)
      end

      module Setup
        def setup &block
          @setup_block = block
        end

        def inherited(subclass)
          subclass.instance_variable_set(:@setup_block, @setup_block)
        end

        def setup_model(model_class, attributes, options = {})
          return unless setup_block = @setup_block
          model_class.class_exec(attributes, options, &setup_block)
        end
      end
    end
  end
end
