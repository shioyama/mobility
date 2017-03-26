require "spec_helper"

describe Mobility::FallthroughAccessors do
  let(:model_class) do
    model_class = stub_const 'MyModel', Class.new
    model_class.class_eval do
      def title
        "title in #{Mobility.locale}"
      end
    end
    model_class.include(described_class.new(:title))
    model_class
  end

  it "handles any locale" do
    instance = model_class.new
    expect(instance.title_fr).to eq("title in fr")
    expect(instance.title_de).to eq("title in de")
  end

  it "raises InvalidLocale if locale is not in I18n.available_locales" do
    instance = model_class.new
    expect { instance.title_ru }.to raise_error(Mobility::InvalidLocale)
  end
end
