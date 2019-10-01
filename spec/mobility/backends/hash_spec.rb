require "spec_helper"
require "mobility/backends/hash"

describe Mobility::Backends::Hash do
  describe "#read/#write" do
    it "returns value for locale key" do
      backend = described_class.new
      expect(backend.read(:ja)).to eq([:ja, nil])
      expect(backend.read(:en)).to eq([:en, nil])
      backend.write(:ja, "アアア")
      expect(backend.read(:ja)).to eq([:ja, "アアア"])
      expect(backend.read(:en)).to eq([:en, nil])
      backend.write(:en, "foo")
      expect(backend.read(:ja)).to eq([:ja, "アアア"])
      expect(backend.read(:en)).to eq([:en, "foo"])
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
    let(:model_class) do
      klass = Class.new
      klass.extend Mobility
      klass.translates :name, backend: :hash
      klass
    end

    it "defines reader and writer methods" do
      instance = model_class.new
      Mobility.with_locale(:en) { instance.name = "foo" }
      Mobility.with_locale(:ja) { instance.name = "アアア" }
      expect(instance.name(locale: :en)).to eq("foo")
      expect(instance.name(locale: :ja)).to eq("アアア")

      expect(instance.name_backend.locales).to match_array([:en, :ja])
    end
  end
end
