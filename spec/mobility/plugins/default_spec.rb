require "spec_helper"
require "mobility/plugins/default"

describe Mobility::Plugins::Default do
  describe "when included into a class" do
    let(:default) { 'default foo' }
    let(:backend_double) { double("backend") }
    let(:backend) { backend_class.new("model", "title", default: default) }
    let(:backend_class) do
      backend_double_ = backend_double
      backend_class = Class.new(Mobility::Backends::Null) do
        define_method :read do |*args|
          backend_double_.read(*args)
        end

        define_method :write do |*args|
          backend_double_.write(*args)
        end
      end
      Class.new(backend_class).include(described_class.new(default))
    end

    describe "#read" do
      it "returns value if not nil" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return("foo")
        expect(backend.read(:fr)).to eq("foo")
      end

      it "returns value if value is false" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(false)
        expect(backend.read(:fr)).to eq(false)
      end

      it "returns default if backend return value is nil" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr)).to eq("default foo")
      end

      it "returns value of default override if passed as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: "default bar")).to eq("default bar")
      end

      it "returns nil if passed default: nil as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: nil)).to eq(nil)
      end

      it "returns false if passed default: false as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: false)).to eq(false)
      end

      context "default is a Proc" do
        let(:default) { lambda { |model:, attribute:| "#{model} #{attribute}" } }

        it "calls default with model and attribute as args if default is a Proc" do
          expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
          expect(backend.read(:fr)).to eq('model title')
        end

        it "calls default with model and attribute as args if default option is a Proc" do
          expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
          expect(backend.read(:fr, default: lambda do |model:, attribute:|
            "#{model} #{attribute} from options"
          end)).to eq('model title from options')
        end
      end
    end
  end

  describe ".apply" do
    it "includes instance of default into backend class" do
      backend_class = double("backend class")
      attributes = instance_double(Mobility::Attributes, backend_class: backend_class)
      default = instance_double(described_class)

      expect(described_class).to receive(:new).with("default").and_return(default)
      expect(backend_class).to receive(:include).with(default)
      described_class.apply(attributes, "default")
    end
  end
end
