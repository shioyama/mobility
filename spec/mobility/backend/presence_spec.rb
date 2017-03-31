require "spec_helper"

describe Mobility::Backend::Presence do
  let(:backend_double) { double("backend") }
  let(:backend) { backend_class.new("model", "attribute") }
  let(:backend_class) do
    backend_double_  = backend_double
    backend_class = Class.new(Mobility::Backend::Null) do
      define_method :read do |*args|
        backend_double_.read(*args)
      end

      define_method :write do |*args|
        backend_double_.write(*args)
      end
    end
    Class.new(backend_class).include(described_class)
  end

  describe "#read" do
    it "passes through present values unchanged" do
      expect(backend_double).to receive(:read).once.with(:fr, {}).and_return("foo")
      expect(backend.read(:fr)).to eq("foo")
    end

    it "converts blank strings to nil" do
      expect(backend_double).to receive(:read).once.with(:fr, {}).and_return("")
      expect(backend.read(:fr)).to eq(nil)
    end

    it "passes through nil values unchanged" do
      expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
      expect(backend.read(:fr)).to eq(nil)
    end

    it "passes through false values unchanged" do
      expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(false)
      expect(backend.read(:fr)).to eq(false)
    end

    it "does not convert blank string to nil if presence: false passed as option" do
      expect(backend_double).to receive(:read).once.with(:fr, {}).and_return("")
      expect(backend.read(:fr, presence: false)).to eq("")
    end
  end

  describe "#write" do
    it "passes through present values unchanged" do
      expect(backend_double).to receive(:write).once.with(:fr, "foo", {}).and_return("foo")
      expect(backend.write(:fr, "foo")).to eq("foo")
    end

    it "converts blank strings to nil" do
      expect(backend_double).to receive(:write).once.with(:fr, nil, {}).and_return(nil)
      expect(backend.write(:fr, "")).to eq(nil)
    end

    it "passes through nil values unchanged" do
      expect(backend_double).to receive(:write).once.with(:fr, nil, {}).and_return(nil)
      expect(backend.write(:fr, nil)).to eq(nil)
    end

    it "passes through false values unchanged" do
      expect(backend_double).to receive(:write).once.with(:fr, false, {}).and_return(false)
      expect(backend.write(:fr, false)).to eq(false)
    end

    it "does not convert blank string to nil if presence: false passed as option" do
      expect(backend_double).to receive(:write).once.with(:fr, "", {}).and_return("")
      expect(backend.write(:fr, "", presence: false)).to eq("")
    end
  end
end
