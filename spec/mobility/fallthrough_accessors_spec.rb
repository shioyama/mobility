require "spec_helper"

describe Mobility::FallthroughAccessors do
  let(:model_class) do
    model_class = stub_const 'MyModel', Class.new
    model_class.class_eval do
      def title
        values[Mobility.locale]
      end

      def title?
        values[Mobility.locale].present?
      end

      def title=(value)
        values[Mobility.locale] = value
      end

      private

      def values
        @values ||= {}
      end
    end
    model_class.include(described_class.new(:title))
    model_class
  end

  it "handles getters and setters in any locale" do
    instance = model_class.new
    expect(instance.title_fr).to eq(nil)
    expect(instance.title_de).to eq(nil)
    instance.title_fr = "Titre"
    expect(instance.title_fr).to eq("Titre")
    instance.title_de = "Titel"
    expect(instance.title_de).to eq("Titel")
  end

  it "handles presence methods in any locale" do
    instance = model_class.new
    expect(instance.title_fr?).to eq(false)
    instance.title_fr = ""
    expect(instance.title_fr?).to eq(false)
    instance.title_fr = "Titre"
    expect(instance.title_fr?).to eq(true)
  end

  it "raises InvalidLocale if locale is not in I18n.available_locales" do
    instance = model_class.new
    expect { instance.title_ru }.to raise_error(Mobility::InvalidLocale)
  end
end
