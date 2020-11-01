# frozen_string_literal: true

module Mobility
=begin

Abstract Module subclass with methods to define plugins and defaults.
Works with {Mobility::Plugin}. (Subclassed by {Mobility::Translations}.)

=end
  class Pluggable < Module
    class << self
      def plugin(name, *args)
        Plugin.configure(self, defaults) { __send__ name, *args }
      end

      def plugins(&block)
        Plugin.configure(self, defaults, &block)
      end

      def included_plugins
        included_modules.grep(Plugin)
      end

      def defaults
        @defaults ||= {}
      end

      def inherited(klass)
        super
        klass.defaults.merge!(defaults)
      end
    end

    def initialize(*, **options)
      initialize_options(options)
      validate_options(@options)
    end

    attr_reader :options

    private

    def initialize_options(options)
      @options = self.class.defaults.merge(options)
    end

    # This is overridden by backend plugin to exclude mixed-in backend options.
    def validate_options(options)
      plugin_keys = self.class.included_plugins.map { |p| Plugins.lookup_name(p) }
      extra_keys = options.keys - plugin_keys
      raise InvalidOptionKey, "No plugin configured for these keys: #{extra_keys.join(', ')}." unless extra_keys.empty?
    end

    class InvalidOptionKey < Error; end
  end
end
