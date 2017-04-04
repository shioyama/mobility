require "spec_helper"

describe Mobility::LocaleAccessors do
  let(:base_model_class) do
    Class.new do
      def title(**_); end
      def title?(**_); end
      def title=(_value, **_); end
    end
  end
  let(:options) { { these: "options" } }

  shared_examples_for "locale accessor" do |locale|
    it "handles getters and setters in any locale in I18n.available_locales" do
      instance = model_class.new

      aggregate_failures "getter" do
        expect(instance).to receive(:title).with(these: "options") do
          expect(Mobility.locale).to eq(locale)
        end.and_return("foo")
        expect(instance.send(:"title_#{locale}", options)).to eq("foo")
      end

      aggregate_failures "presence" do
        expect(instance).to receive(:title?).with(these: "options") do
          expect(Mobility.locale).to eq(locale)
        end.and_return(true)
        expect(instance.send(:"title_#{locale}?", options)).to eq(true)
      end

      aggregate_failures "setter" do
        expect(instance).to receive(:title=).with("value", these: "options") do
          expect(Mobility.locale).to eq(locale)
        end.and_return("value")
        expect(instance.send(:"title_#{locale}=", "value", options)).to eq("value")
      end
    end
  end

  context "locales unset" do
    before do
      @available_locales = I18n.available_locales
      I18n.available_locales = [:en, :ko, :pt]
    end
    after do
      I18n.available_locales = @available_locales
    end
    let(:model_class) do
      base_model_class.include described_class.new(:title)
      base_model_class
    end

    it_behaves_like "locale accessor", :pt

    it "raises NoMethodError if locale not in I18n.available_locales" do
      model_class.include(described_class.new(:title))
      instance = model_class.new
      aggregate_failures do
        expect { instance.title_de }.to raise_error(NoMethodError)
        expect { instance.title_de? }.to raise_error(NoMethodError)
        expect { instance.send(:title_de=, "value", options) }.to raise_error(NoMethodError)
      end
    end
  end

  context "locales set" do
    let(:model_class) do
      base_model_class.include described_class.new(:title, locales: [:cz, :de])
    end

    it_behaves_like "locale accessor", :cz
    it_behaves_like "locale accessor", :de

    it "raises NoMethodError if locale not in locales" do
      instance = model_class.new
      aggregate_failures do
        expect { instance.title_en }.to raise_error(NoMethodError)
        expect { instance.title_en? }.to raise_error(NoMethodError)
        expect { instance.send(:title_en=, "value", options) }.to raise_error(NoMethodError)
      end
    end
  end
end
