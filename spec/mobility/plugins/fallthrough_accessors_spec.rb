require "spec_helper"
require "mobility/plugins/fallthrough_accessors"

describe Mobility::Plugins::FallthroughAccessors, type: :plugin do
  plugin_setup :title
  let(:translation_options) { {} }
  let(:model_class) do
    klass = Class.new do
      def title(**); end
      def title?(**); end
      def title=(_, **); end
    end
    klass.include translations
    klass
  end

  context "option value is default" do
    plugins do
      fallthrough_accessors
    end

    it_behaves_like "locale accessor", :title, 'en'
    it_behaves_like "locale accessor", :title, 'de'
    it_behaves_like "locale accessor", :title, 'pt-BR'
    it_behaves_like "locale accessor", :title, 'rus'

    it 'passes arguments and options to super when method does not match' do
      mod = Module.new do
        def method_missing(method_name, *args, &block)
          (method_name == :foo) ? args : super
        end
      end

      model_class = Class.new
      model_class.include translations, mod

      instance = model_class.new

      options = { some: 'params' }
      expect(instance.foo(**options)).to eq([options])
    end

    it 'passes kwargs to super when method does not match' do
      mod = Module.new do
        def method_missing(method_name, *args, **kwargs, &block)
          (method_name == :foo) ? [args, kwargs] : super
        end
      end

      model_class = Class.new
      model_class.include translations, mod

      instance = model_class.new

      kwargs = { some: 'params' }
      expect(instance.foo(**kwargs)).to eq([[], kwargs])
    end

    it 'does not pass on empty keyword options hash to super' do
      mod = Module.new do
        def method_missing(method_name, *args, &block)
          method_name == :bar ? args : super
        end
      end

      model_class = Class.new
      model_class.include translations, mod

      instance = model_class.new

      expect(instance.bar).to eq([])
    end
  end

  context "option value is false" do
    plugins do
      fallthrough_accessors false
    end

    it "does not include instance of FallthroughAccessors into attributes class" do
      instance = model_class.new
      expect { instance.title_en }.to raise_error(NoMethodError)
      expect { instance.title_en? }.to raise_error(NoMethodError)
      expect { instance.send(:title_en=, "value", {}) }.to raise_error(NoMethodError)
    end
  end
end
