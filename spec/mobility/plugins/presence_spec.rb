require "spec_helper"
require "mobility/plugins/presence"

describe Mobility::Plugins::Presence do
  include Helpers::Plugins

  context "option = true" do
    plugin_setup presence: true

    describe "#read" do
      it "passes through present values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, "foo"])
        expect(backend.read(:fr)).to eq([:fr, "foo"])
      end

      it "converts blank strings to nil" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, ""])
        expect(backend.read(:fr)).to eq([:fr, nil])
      end

      it "passes through nil values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, nil])
        expect(backend.read(:fr)).to eq([:fr, nil])
      end

      it "passes through false values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, false])
        expect(backend.read(:fr)).to eq([:fr, false])
      end

      it "does not convert blank string to nil if presence: false passed as option" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, ""])
        expect(backend.read(:fr, presence: false)).to eq([:fr, ""])
      end

      it "does not modify options passed in" do
        options = { presence: false }
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, ""])
        backend.read(:fr, options)
        expect(options).to eq({ presence: false })
      end
    end

    describe "#write" do
      it "passes through present values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, "foo", {}).and_return([:fr, "foo"])
        expect(backend.write(:fr, "foo")).to eq([:fr, "foo"])
      end

      it "converts blank strings to nil" do
        expect(listener).to receive(:write).once.with(:fr, nil, {}).and_return([:fr, nil])
        expect(backend.write(:fr, "")).to eq([:fr, nil])
      end

      it "passes through nil values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, nil, {}).and_return([:fr, nil])
        expect(backend.write(:fr, nil)).to eq([:fr, nil])
      end

      it "passes through false values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, false, {}).and_return([:fr, false])
        expect(backend.write(:fr, false)).to eq([:fr, false])
      end

      it "does not convert blank string to nil if presence: false passed as option" do
        expect(listener).to receive(:write).once.with(:fr, "", {}).and_return([:fr, ""])
        expect(backend.write(:fr, "", presence: false)).to eq([:fr, ""])
      end

      it "does not modify options passed in" do
        options = { presence: false }
        expect(listener).to receive(:write).once.with(:fr, "foo", {})
        backend.write(:fr, "foo", options)
        expect(options).to eq({ presence: false })
      end
    end
  end

  context "option = false" do
    plugin_setup presence: false

    describe "#read" do
      it "does not convert blank strings to nil" do
        expect(listener).to receive(:read).once.with(:fr, {}).and_return([:fr, ""])
        expect(backend.read(:fr)).to eq([:fr, ""])
      end
    end

    describe "#write" do
      it "does not convert blank strings to nil" do
        expect(listener).to receive(:write).once.with(:fr, "", {}).and_return([:fr, ""])
        expect(backend.write(:fr, "")).to eq([:fr, ""])
      end
    end
  end
end
