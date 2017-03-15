# frozen-string-literal: true

module Mobility
  class TranslationsGenerator < ::Rails::Generators::NamedBase
    BACKENDS = %w[column key_value hstore jsonb serialized table]
    BACKEND_OPTIONS = { type: :string, desc: "Backend to use for translations (defaults to Mobility.default_backend)".freeze }
    argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"

    class_option(:backend, BACKEND_OPTIONS)
    invoke_from_option :backend

    def self.class_options(options = nil)
      super
      @class_options[:backend] = Thor::Option.new(:backend, BACKEND_OPTIONS.merge(default: Mobility.default_backend.to_s.freeze))
      @class_options
    end

    def self.prepare_for_invocation(name, value)
      if name == :backend
        require_relative "./backend_generators/#{value}_backend".freeze
        Mobility::BackendGenerators.const_get("#{value}_backend".camelcase.freeze)
      else
        super
      end
    end

    protected

    def say_status(status, message, *args)
      if status == :invoke && BACKENDS.include?(message)
        super(status, "#{message}_backend".freeze, *args)
      else
        super
      end
    end
  end
end
