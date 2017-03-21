require "spec_helper"

describe Mobility::Backend::Fallbacks do
  let(:backend_class) do
    backend_class = stub_const 'MyBackend', Class.new
    backend_class.include(Mobility::Backend)
    backend_class.class_eval do
      def read(locale, **options)
        return "bar" if options[:bar]
        {
          "title" => {
            :'de-DE' => "foo",
            :ja => "フー",
            :'pt' => ""
          }
        }[attribute][locale]
      end
    end
    backend_class = Class.new(backend_class).include(described_class)
    backend_class
  end
  let(:object) { (stub_const 'MobilityModel', Class.new).include(Mobility).new }

  context "fallbacks is a hash" do
    subject do
      backend_class.new(object, "title", fallbacks: { :'en-US' => 'de-DE', :pt => 'de-DE' })
    end

    it "returns value when value is not nil" do
      expect(subject.read(:ja)).to eq("フー")
    end

    it "falls through to fallback locale when value is nil" do
      expect(subject.read(:"en-US")).to eq("foo")
    end

    it "falls through to fallback locale when value is blank" do
      expect(subject.read(:pt)).to eq("foo")
    end

    it "returns nil when no fallback is found" do
      expect(subject.read(:"fr")).to eq(nil)
    end

    it "returns nil when fallbacks: false option is passed" do
      expect(subject.read(:"en-US", fallback: false)).to eq(nil)
    end

    it "uses locale passed in as value of fallback option when present" do
      expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
    end

    it "uses array of locales passed in as value of fallback options when present" do
      expect(subject.read(:"en-US", fallback: [:es, :'de-DE'])).to eq("foo")
    end

    it "passes options to getter in fallback locale" do
      expect(subject.read(:'en-US', bar: true)).to eq("bar")
    end
  end

  context "fallbacks is true" do
    subject do
      backend_class.new(object, "title", fallbacks: true)
    end

    it "uses default fallbacks" do
      original_default_locale = I18n.default_locale
      I18n.default_locale = :ja
      expect(subject.read(:"en-US")).to eq("フー")
      I18n.default_locale = original_default_locale
    end
  end

  context "fallbacks is falsey" do
    subject { backend_class.new(object, "title") }

    it "does not use fallbacks" do
      original_default_locale = I18n.default_locale
      I18n.default_locale = :ja
      expect(subject.read(:"en-US")).to eq(nil)
      I18n.default_locale = original_default_locale
    end
  end
end
