require 'spec_helper'

describe Mobility::Backend do
  context "included in backend" do
    before do
      backend = stub_const 'MyBackend', Class.new
      backend.include described_class
    end
    let(:attribute) { "title" }
    let(:model) { double("model") }

    context "with no options" do
      subject { MyBackend.new(model, attribute) }

      it "assigns attribute" do
        expect(subject.attribute).to eq(attribute)
      end

      it "assigns model" do
        expect(subject.model).to eq(model)
      end
    end

    context "with options" do
      subject { MyBackend.new(model, attribute, options) }
      let(:options) { { foo: "bar" } }

      it "assigns options" do
        expect(subject.options).to eq(options)
      end

      context "with fallbacks" do
        let(:options) { { fallbacks: { :'en-US' => 'de-DE' } } }

        it "sets @fallbacks variable" do
          expect(subject.instance_variable_get(:'@fallbacks')).to eq(I18n::Locale::Fallbacks.new(:'en-US' => 'de-DE'))
        end
      end
    end

    describe ".setup" do
      before do
        MyBackend.class_eval do
          setup do
            def self.foo
              "foo"
            end
            def bar
              "bar"
            end
          end
        end
      end

      it "stores setup as block which is called in model class" do
        model_class = Class.new
        MyBackend.setup_model(model_class, ["title"], { foo: "bar" })
        expect(model_class.foo).to eq("foo")
        expect(model_class.new.bar).to eq("bar")
      end

      it "assigns setup block to descendants" do
        model_class = Class.new
        other_backend = Class.new(MyBackend)
        other_backend.setup_model(model_class, ["title"], { foo: "bar" })
        expect(model_class.foo).to eq("foo")
      end
    end

  end

  describe ".method_name" do
    it "returns <attribute>_translations" do
      expect(Mobility::Backend.method_name("foo")).to eq("foo_translations")
    end
  end
end
