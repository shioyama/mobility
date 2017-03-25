# frozen-string-literal: true

module Mobility
=begin

Generator to create translation tables or add translation columns to a model
table, for either Table or Column backends.

==Usage

To add translations for a string attribute +title+ to a model +Post+, call the
generator with:

  rails generate mobility:translations post title:string

Here, the backend is implicit in the value of +Mobility.default_backend+, but
it can be explicitly set using the +backend+ option:

  rails generate mobility:translations post title:string --backend=table

For the +table+ backend, the generator will either create a translation table
(in this case, +post_translations+) or add columns to the table if it already
exists.

For the +column+ backend, the generator will add columns for all locales in
+I18n.available_locales+. If some columns already exist, they will simply be
skipped.

Other backends are not supported, for obvious reasons:
* the +key_value+ backend does not need any model-specific migrations, simply
  run the install generator.
* +jsonb+, +hstore+ and +serialized+ backends simply require a single column on
  a model table, which can be added with the normal Rails migration generator.

=end
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
