require "spec_helper"
require "mobility/plugins/dirty"

describe Mobility::Plugins::Dirty do
  include Helpers::Plugins

  context "option value is truthy" do
    plugin_setup dirty: true

    shared_examples_for "dirty module" do
      let(:methods_class) { parent_module.const_get("MethodsBuilder") }
      let(:backend_methods) { parent_module.const_get("BackendMethods") }
      let(:methods) { methods_class.new(attribute_name) }
      before { expect(methods_class).to receive(:new).with(attribute_name).and_return(methods) }

      it "includes dirty module model class" do
        model_class.include attributes
        expect(model_class.ancestors).to include(methods)
      end

      it "includes backend methods into backend class" do
        model_class.include attributes
        expect(model_class.mobility_backend_class(attribute_name).ancestors).to include(backend_methods)
      end
    end

    context "model_class includes ActiveModel::Dirty", orm: :active_record do
      context "including class is an ActiveRecord::Base" do
        it_behaves_like "dirty module" do
          let(:parent_module) { Mobility::Plugins::ActiveRecord::Dirty }
          let(:model_class) { Class.new(ActiveRecord::Base) }
        end
      end

      context "including class is not an ActiveRecord::Base" do
        it_behaves_like "dirty module" do
          let(:parent_module) { Mobility::Plugins::ActiveModel::Dirty }
          let(:model_class) do
            Class.new.tap do |klass|
              klass.include(ActiveModel::Dirty)
            end
          end
        end
      end
    end

    context "options[:model_class] is a Sequel::Model", orm: :sequel do
      it_behaves_like "dirty module" do
        let(:parent_module) { Mobility::Plugins::Sequel::Dirty }
        let(:model_class) { Class.new(Sequel::Model) }
      end
    end
  end

  context "option value is falsey" do
    plugin_setup dirty: false

    it "does not include Mobility::Plugins::FallthroughAccessors" do
      expect(attributes.options[:fallthrough_accessors]).not_to be_truthy
      model_class.include attributes
    end

    it "does not include any dirty modules into backend class" do
      model_class.include attributes
      ancestors = model_class.mobility_backend_class(attribute_name).ancestors
      expect(ancestors.select { |mod| mod.name =~ /Dirty/ }).to be_empty
    end
  end
end
