require "spec_helper"

describe Mobility::Attributes, orm: 'none' do
  include Helpers::Backend
  before { stub_const 'Article', Class.new }

  # In order to be able to stub methods on backend instance methods, which will be
  # hidden when the backend class is subclassed in Attributes, we inject a double
  # and delegate read and write to the double. (Nice trick, eh?)
  #
  let(:listener) { double("backend") }
  let(:backend_class) { backend_listener(listener) }
  let(:backend) { backend_class.new }
  let(:model_class) { Article }

  # These options disable all inclusion of modules into backend, which is useful
  # for many specs in this suite.
  let(:clean_options) { { cache: false, fallbacks: false, presence: false } }

  describe "including Attributes in a model" do
    let(:expected_options) { { foo: "bar", **Mobility.default_options, model_class: model_class } }

    describe "model class methods" do
      describe ".mobility_attributes" do
        it "returns attribute names" do
          model_class.include described_class.new("title", "content", backend: backend_class)
          model_class.include described_class.new("foo", backend: backend_class)

          expect(model_class.send(:mobility_attributes)).to match_array(["title", "content", "foo"])
        end

        it "only returns unique attributes" do
          model_class.include described_class.new("title", backend: :null)
          model_class.include described_class.new("title", backend: :null)

          expect(model_class.send(:mobility_attributes)).to eq(["title"])
        end
      end

      describe ".mobility_attribute?" do
        it "returns true if and only if attribute name is translated" do
          names = %w[title content]
          model_class.include described_class.new(*names, backend: :null)
          names.each do |name|
            expect(model_class.mobility_attribute?(name)).to eq(true)
            expect(model_class.mobility_attribute?(name.to_sym)).to eq(true)
          end
          expect(model_class.mobility_attribute?("foo")).to eq(false)
        end
      end
    end
  end

  describe "#each" do
    it "delegates to attributes" do
      attributes = described_class.new("title", "content", backend: :null)
      expect { |b| attributes.each(&b) }.to yield_successive_args("title", "content")
    end
  end

  describe "#inspect" do
    it "returns attribute names" do
      attributes = described_class.new("title", "content")
      expect(attributes.inspect).to eq("#<Attributes @names=title, content>")
    end
  end
end
