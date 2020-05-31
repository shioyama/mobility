module Helpers
  def stringify_keys(hash)
    result = Hash.new
    hash.each_key { |key| result[key.to_s] = hash[key] }
    result
  end

  def self.included(base)
    base.extend LazyDescribedClass
  end

  # Reset I18n.fallbacks to nil, necessary in case the default locale is
  # changed since I18n.fallbacks implicitly stores the previous default locale
  # as @@defaults.
  def reset_i18n_fallbacks
    I18n.class_variable_set(:@@fallbacks, nil)
  end

  module LazyDescribedClass
    # lazy-load described_class if it's a string
    def described_class
      klass = super
      return klass if klass

      # crawl up metadata tree looking for description that can be constantized
      this_metadata = metadata
      while this_metadata do
        candidate = this_metadata[:description_args].first
        begin
          return candidate.constantize if String === candidate
        rescue NameError, NoMethodError
        end
        this_metadata = this_metadata[:parent_example_group]
      end
    end
  end

  module Backend
    def include_backend_examples *args
      it_behaves_like "Mobility backend", *args
    end

    def include_dup_examples *args
      it_behaves_like "dupable model", *args
    end

    def include_cache_key_examples *args
      it_behaves_like "cache key", *args
    end

    def backend_listener(listener)
      Class.new.tap do |klass|
        klass.class_eval do
          include Mobility::Backend
          define_method :read do |*args, **opts|
            listener.read(*args, **opts)
          end

          define_method :write do |*args, **opts|
            listener.write(*args, **opts)
          end
        end
      end
    end

  end

  module ActiveRecord
    include Backend

    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "AR Model with translated scope", *args
    end

    def include_serialization_examples *args
      it_behaves_like "AR Model with serialized translations", *args
    end

    def include_validation_examples *args
      it_behaves_like "AR Model validation", *args
    end
  end

  module Sequel
    include Backend

    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
      it_behaves_like "Sequel model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "Sequel Model with translated dataset", *args
    end

    def include_serialization_examples *args
      it_behaves_like "Sequel Model with serialized translations", *args
    end
  end

  module Generators
    def version_string
      "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}"
    end
  end

  module Plugins
    include Backend

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Sets up attributes module with a listener to listen on reads/writes to the
      # backend. Pass two separate arrays to create separate attributes modules.
      def plugin_setup(attribute_name = "title", *other_names, **options)
        plugin_names = options.keys & Dir['./lib/mobility/plugins/*.rb'].map { |f| File.basename(f, '.rb').to_sym }

        # Handle special case of backend plugin. If we pass plugin: true, we
        # want to enable the backend plugin but use the backend listener.
        options.delete(:backend) if options[:backend] == true

        attribute_names = [attribute_name, *other_names]
        let(:attribute_name) { attribute_name }
        let(:attributes_class) do
          Class.new(TestAttributes).tap do |attrs|
            plugin_names.each { |plugin| attrs.plugin plugin }
          end
        end
        let(:model_class) do
          Class.new.tap do |klass|
            klass.include attributes
          end
        end
        let(:instance) { model_class.new }

        let(:attributes) { attributes_class.new(*attribute_names, backend: backend_class, **options) }
        let(:listener) { double(:backend) }
        let(:backend_class) { backend_listener(listener) }
        let(:backend) { instance.mobility_backends[attribute_name] }
        attribute_names.each { |name| let(:"#{name}_backend") { instance.send("#{name}_backend") } }
      end
    end
  end
end
