require "spec_helper"
require "mobility/backends/hash"

describe Mobility::Backends::Hash, type: :backend, orm: :none do
  describe "#read/#write" do
    it "returns value for locale key" do
      backend = described_class.new
      expect(backend.read(:ja)).to eq(nil)
      expect(backend.read(:en)).to eq(nil)
      backend.write(:ja, "アアア")
      expect(backend.read(:ja)).to eq("アアア")
      expect(backend.read(:en)).to eq(nil)
      backend.write(:en, "foo")
      expect(backend.read(:ja)).to eq("アアア")
      expect(backend.read(:en)).to eq("foo")
    end
  end

  describe "#each_locale" do
    it "returns keys of hash to block" do
      backend = described_class.new
      backend.write(:ja, "アアア")
      backend.write(:en, "aaa")
      expect { |b| backend.each_locale(&b) }.to yield_successive_args(:ja, :en)
    end
  end

  context "included in model" do
    plugins :reader, :writer

    before do
      stub_const 'HashPost', Class.new
      translates HashPost, :name, backend: :hash
    end

    it "defines reader and writer methods" do
      instance = HashPost.new
      Mobility.with_locale(:en) { instance.name = "foo" }
      Mobility.with_locale(:ja) { instance.name = "アアア" }
      expect(instance.name(locale: :en)).to eq("foo")
      expect(instance.name(locale: :ja)).to eq("アアア")

      expect(backend_for(instance, :name).locales).to match_array([:en, :ja])
    end
  end
end
