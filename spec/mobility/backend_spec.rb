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

    describe ".setup" do
      before do
        MyBackend.class_eval do
          setup do |attributes, options|
            def self.foo
              "foo"
            end
            def bar
              "bar"
            end
            define_method :my_attributes do
              attributes
            end
            define_method :my_options do
              options
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

      it "passes attributes and options to setup block when called on class" do
        model_class = Class.new
        MyBackend.setup_model(model_class, ["title"], { foo: "bar" })
        expect(model_class.new.my_attributes).to eq(["title"])
        expect(model_class.new.my_options).to eq({ foo: "bar" })
      end

      it "assigns setup block to descendants" do
        model_class = Class.new
        other_backend = Class.new(MyBackend)
        other_backend.setup_model(model_class, ["title"], { foo: "bar" })
        expect(model_class.foo).to eq("foo")
      end

      it "concatenates blocks when called multiple times" do
        MyBackend.class_eval do
          setup do |attributes, options|
            def self.foo
              "foo2"
            end
            define_method :baz do
              "#{attributes.join} baz"
            end
            def self.foobar
              "foobar"
            end
          end
        end
        model_class = Class.new
        MyBackend.setup_model(model_class, ["title", "content"], { foo: "bar" })

        aggregate_failures do
          expect(model_class.foo).to eq("foo2")
          expect(model_class.new.baz).to eq("titlecontent baz")
          expect(model_class.foobar).to eq("foobar")
        end
      end
    end

  end

  describe ".method_name" do
    it "returns <attribute>_translations" do
      expect(Mobility::Backend.method_name("foo")).to eq("foo_backend")
    end
  end
end
