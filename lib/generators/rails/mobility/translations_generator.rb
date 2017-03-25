# frozen-string-literal: true

module Mobility
  class TranslationsGenerator < ::Rails::Generators::NamedBase
    SUPPORTED_BACKENDS = %w[column table]
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
        if SUPPORTED_BACKENDS.include?(value)
          require_relative "./backend_generators/#{value}_backend".freeze
          Mobility::BackendGenerators.const_get("#{value}_backend".camelcase.freeze)
        elsif Mobility::Backend.const_get(value.to_s.camelize.gsub(/\s+/, ''.freeze))
          raise Thor::Error, "The #{value} backend does not have a translations generator."
        else
          raise Thor::Error, "#{value} is not a Mobility backend."
        end
      else
        super
      end
    end

    protected

    def say_status(status, message, *args)
      if status == :invoke && SUPPORTED_BACKENDS.include?(message)
        super(status, "#{message}_backend".freeze, *args)
      else
        super
      end
    end
  end
end
