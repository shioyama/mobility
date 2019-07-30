require "spec_helper"
require "mobility/plugins/fallbacks"

describe Mobility::Plugins::Fallbacks do
  describe "when included into a class" do
    let(:backend_class) do
      backend_class = stub_const 'MyBackend', Class.new
      backend_class.include(Mobility::Backend)
      backend_subclass = backend_class.with_options(fallbacks: fallbacks) do
        def read(locale, **options)
          Mobility.enforce_available_locales!(locale)
          return "bar" if options[:bar]
          {
            "title" => {
              :'de-DE' => "foo",
              :ja => "フー",
              :'pt' => "",
              :'cz' => "cz-foo"
            }
          }[attribute][locale]
        end
      end
      Class.new(backend_subclass).include(described_class.new(fallbacks))
    end
    let(:object) do
      (stub_const 'MobilityModel', Class.new)
        .include(Mobility)
        .include(
          Module.new do
            def fallback_locale_method
              'de-DE'
            end
          end
      ).new
    end
    subject { backend_class.new(object, "title") }

    context "fallbacks is a hash" do
      let(:fallbacks) { { :'en-US' => 'de-DE', :pt => 'de-DE' } }

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
        expect(subject.read(:fr)).to eq(nil)
      end

      it "returns nil when fallback: false option is passed" do
        expect(subject.read(:"en-US", fallback: false)).to eq(nil)
      end

      it "falls through to fallback locale when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq("foo")
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'cz'])).to eq("cz-foo")
      end

      it "passes options to getter in fallback locale" do
        expect(subject.read(:'en-US', bar: true)).to eq("bar")
      end

      it "does not modify options passed in" do
        options = { fallback: false }
        subject.read(:"en-US", options)
        expect(options).to eq({ fallback: false })
      end
    end

    context "fallbacks is a proc returning a locale" do
      let(:fallbacks) { proc { 'de-DE' } }

      it "returns value when value is not nil" do
        expect(subject.read(:ja)).to eq("フー")
      end

      it "falls through to fallback locale when value is nil" do
        expect(subject.read(:"en-US")).to eq("foo")
      end

      it "falls through to fallback locale when value is blank" do
        expect(subject.read(:pt)).to eq("foo")
      end

      it "falls through to fallback locale when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq("foo")
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("foo")
      end

      it "passes options to getter in fallback locale" do
        expect(subject.read(:'en-US', bar: true)).to eq("bar")
      end

      it "does not modify options passed in" do
        options = { fallback: false }
        subject.read(:"en-US", options)
        expect(options).to eq({ fallback: false })
      end
    end

    context "fallbacks is a proc returning nothing" do
      let(:fallbacks) { proc {} }

      it "returns value when value is not nil" do
        expect(subject.read(:ja)).to eq("フー")
      end

      it "returns original value when value is nil" do
        expect(subject.read(:"en-US")).to eq(nil)
      end

      it "returns original value when value is blank" do
        expect(subject.read(:pt)).to eq("")
      end

      it "returns original value when value when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq(nil)
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("foo")
      end

      it "passes options to getter in fallback locale" do
        expect(subject.read(:'en-US', bar: true)).to eq("bar")
      end

      it "does not modify options passed in" do
        options = { fallback: false }
        subject.read(:"en-US", options)
        expect(options).to eq({ fallback: false })
      end
    end

    context "fallbacks is a proc returning an array" do
      let(:fallbacks) { proc { [:pl, :'de-DE'] } }

      it "returns value when value is not nil" do
        expect(subject.read(:ja)).to eq("フー")
      end

      it "returns fallback value when value is nil" do
        expect(subject.read(:"en-US")).to eq("foo")
      end

      it "returns fallback value when value is blank" do
        expect(subject.read(:pt)).to eq("foo")
      end

      it "returns fallback value when value when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq("foo")
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("foo")
      end

      it "passes options to getter in fallback locale" do
        expect(subject.read(:'en-US', bar: true)).to eq("bar")
      end

      it "does not modify options passed in" do
        options = { fallback: false }
        subject.read(:"en-US", options)
        expect(options).to eq({ fallback: false })
      end
    end

    context "fallbacks is a proc calling a model method" do
      let(:fallbacks) { proc { fallback_locale_method } }

      it "returns value when value is not nil" do
        expect(subject.read(:ja)).to eq("フー")
      end

      it "falls through to fallback locale when value is nil" do
        expect(subject.read(:"en-US")).to eq("foo")
      end

      it "falls through to fallback locale when value is blank" do
        expect(subject.read(:pt)).to eq("foo")
      end

      it "falls through to fallback locale when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq("foo")
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("foo")
      end

      it "passes options to getter in fallback locale" do
        expect(subject.read(:'en-US', bar: true)).to eq("bar")
      end

      it "does not modify options passed in" do
        options = { fallback: false }
        subject.read(:"en-US", options)
        expect(options).to eq({ fallback: false })
      end
    end

    context "fallbacks is true" do
      let(:fallbacks) { true }

      # @note I18n changed its behavior in 1.1 (see: https://github.com/svenfuchs/i18n/pull/415)
      #   To correctly test all versions, we actually generate fallbacks and
      #   determine what the value should be, then check that it matches the
      #   actual fallback value.
      # TODO: Simplify this when support for I18n < 1.1 is dropped.
      it "uses default fallbacks" do
        original_default_locale = I18n.default_locale
        I18n.default_locale = :ja
        fallbacks = Mobility::Fallbacks.build({})
        locales = fallbacks[:"en-US"]
        # in I18n 1.1 value is nil here
        value = locales.map { |locale| subject.read(locale, locale: true) }.compact.first
        expect(subject.read(:"en-US")).to eq(value)
        I18n.default_locale = original_default_locale
      end
    end

    context "fallbacks is falsey" do
      let(:fallbacks) { nil }

      it "does not use fallbacks when fallback option is false or nil" do
        original_default_locale = I18n.default_locale
        I18n.default_locale = :ja
        expect(subject.read(:"en-US")).to eq(nil)
        I18n.default_locale = original_default_locale
        expect(subject.read(:"en-US", fallback: false)).to eq(nil)
        I18n.default_locale = original_default_locale
      end

      it "uses locale passed in as value of fallback option when present" do
        expect(subject.read(:"en-US", fallback: :ja)).to eq("フー")
      end

      it "uses array of locales passed in as value of fallback options when present" do
        expect(subject.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("foo")
      end

      it "does not use fallbacks when fallback: true option is passed" do
        expect(subject.read(:"en-US", fallback: true)).to eq(nil)
      end
    end
  end

  describe ".apply" do
    let(:attributes) { instance_double(Mobility::Attributes, backend_class: backend_class) }
    let(:backend_class) { double("backend class") }
    let(:fallbacks) { instance_double(described_class) }

    context "option value is not false" do
      it "includes instance of fallbacks into backend class" do
        expect(described_class).to receive(:new).with("option").and_return(fallbacks)
        expect(backend_class).to receive(:include).with(fallbacks)
        described_class.apply(attributes, "option")
      end
    end

    context "optoin value is false" do
      it "does nothing" do
        expect(attributes).not_to receive(:backend_class)
        described_class.apply(attributes, false)
      end
    end
  end
end
