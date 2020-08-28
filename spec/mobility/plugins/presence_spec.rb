require "spec_helper"
require "mobility/plugins/presence"

describe Mobility::Plugins::Presence do
  include Helpers::Plugins

  context "default option value" do
    plugin_setup do
      presence
    end

    describe "#read" do
      it "passes through present values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return("foo")
        expect(backend.read(:fr)).to eq("foo")
      end

      it "converts blank strings to nil" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return("")
        expect(backend.read(:fr)).to eq(nil)
      end

      it "passes through nil values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return(nil)
        expect(backend.read(:fr)).to eq(nil)
      end

      it "passes through false values unchanged" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return(false)
        expect(backend.read(:fr)).to eq(false)
      end

      it "does not convert blank string to nil if presence: false passed as option" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return("")
        expect(backend.read(:fr, presence: false)).to eq("")
      end

      it "does not modify options passed in" do
        options = { presence: false }
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return("")
        backend.read(:fr, options)
        expect(options).to eq({ presence: false })
      end
    end

    describe "#write" do
      it "passes through present values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, "foo", any_args).and_return("foo")
        expect(backend.write(:fr, "foo")).to eq("foo")
      end

      it "converts blank strings to nil" do
        expect(listener).to receive(:write).once.with(:fr, nil, any_args).and_return(nil)
        expect(backend.write(:fr, "")).to eq(nil)
      end

      it "passes through nil values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, nil, any_args).and_return(nil)
        expect(backend.write(:fr, nil)).to eq(nil)
      end

      it "passes through false values unchanged" do
        expect(listener).to receive(:write).once.with(:fr, false, any_args).and_return(false)
        expect(backend.write(:fr, false)).to eq(false)
      end

      it "does not convert blank string to nil if presence: false passed as option" do
        expect(listener).to receive(:write).once.with(:fr, "", any_args).and_return("")
        expect(backend.write(:fr, "", presence: false)).to eq("")
      end

      it "does not modify options passed in" do
        options = { presence: false }
        expect(listener).to receive(:write).once.with(:fr, "foo", any_args)
        backend.write(:fr, "foo", options)
        expect(options).to eq({ presence: false })
      end
    end
  end

  context "option = false" do
    plugin_setup do
      presence false
    end

    describe "#read" do
      it "does not convert blank strings to nil" do
        expect(listener).to receive(:read).once.with(:fr, any_args).and_return("")
        expect(backend.read(:fr)).to eq("")
      end
    end

    describe "#write" do
      it "does not convert blank strings to nil" do
        expect(listener).to receive(:write).once.with(:fr, "", any_args).and_return("")
        expect(backend.write(:fr, "")).to eq("")
      end
    end
  end
end
