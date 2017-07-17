require "spec_helper"

describe Mobility::Translates do
  before do
    stub_const('MyClass', Class.new).extend(Mobility::Translates)
  end
  let(:attribute_names) { [:title, :content] }

  describe ".mobility_accessor" do
    it "includes new Attributes module" do
      attributes = Module.new do
        def self.each &block; end
      end
      expect(Mobility::Attributes).to receive(:new).with(:accessor, *attribute_names, {}).and_return(attributes)
      MyClass.mobility_accessor *attribute_names
    end

    it "yields to block with backend as context if block given" do
      attributes = Module.new do
        def self.backend; end
        def self.each &block; end
      end
      backend = double("backend")
      expect(attributes).to receive(:backend).and_return(backend)
      expect(backend).to receive(:foo).with("bar")
      allow(Mobility::Attributes).to receive(:new).and_return(attributes)
      MyClass.mobility_accessor :title do
        foo("bar")
      end
    end

    describe "aliasing attribute getter/setter methods" do
      let(:attributes) do
        _attribute_names = attribute_names
        Module.new do
          define_singleton_method :each do |&block|
            _attribute_names.each &block
          end
        end
      end
      before { allow(Mobility::Attributes).to receive(:new).and_return(attributes) }

      describe ".mobility_accessor" do
        it "aliases getter and setter methods if defined to <attribute>_before_mobility and <attribute_before_mobility=" do
          MyClass.class_eval do
            def title
              "foo"
            end

            def title=(value)
              value
            end
          end
          MyClass.mobility_accessor *attribute_names
          expect(MyClass.new.title).to eq("foo")
          expect(MyClass.new.title_before_mobility).to eq("foo")
          expect(MyClass.new.title="baz").to eq("baz")
          expect(MyClass.new.title_before_mobility="baz").to eq("baz")
          expect { MyClass.new.content }.to raise_error(NoMethodError)
          expect { MyClass.new.content_before_mobility }.to raise_error(NoMethodError)
          expect { MyClass.new.content=("foo") }.to raise_error(NoMethodError)
          expect { MyClass.new.content_before_mobility=("foo") }.to raise_error(NoMethodError)
        end
      end

      describe ".mobility_reader" do
        it "aliases getter methods only if defined to <attribute>_before_mobility" do
          MyClass.class_eval do
            def title
              "foo"
            end

            def title=(value)
              value
            end
          end
          MyClass.mobility_reader *attribute_names
          expect(MyClass.new.title).to eq("foo")
          expect(MyClass.new.title_before_mobility).to eq("foo")
          expect(MyClass.new.title="baz").to eq("baz")
          expect { MyClass.new.title_before_mobility=("baz") }.to raise_error(NoMethodError)
        end
      end

      describe ".mobility_writer" do
        it "aliases getter methods only if defined to <attribute>_before_mobility=" do
          MyClass.class_eval do
            def title
              "foo"
            end

            def title=(value)
              value
            end
          end
          MyClass.mobility_writer *attribute_names
          expect(MyClass.new.title).to eq("foo")
          expect { MyClass.new.title_before_mobility }.to raise_error(NoMethodError)
          expect(MyClass.new.title="baz").to eq("baz")
          expect(MyClass.new.title_before_mobility=("baz")).to eq("baz")
        end
      end
    end
  end
end
