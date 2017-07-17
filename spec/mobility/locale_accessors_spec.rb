require "spec_helper"

describe Mobility::LocaleAccessors do
  let(:base_model_class) do
    Class.new do
      def title(**_); end
      def title?(**_); end
      def title=(_value, **_); end
    end
  end

  context "locales unset, uses I18n.available_locales" do
    before do
      @available_locales = I18n.available_locales
      I18n.available_locales = [:en, :pt]
    end
    after do
      I18n.available_locales = @available_locales
    end
    let(:model_class) do
      base_model_class.include described_class.new(:title)
      base_model_class
    end

    it_behaves_like "locale accessor", :title, :pt

    it "raises NoMethodError if locale not in I18n.available_locales" do
      model_class.include(described_class.new(:title))
      instance = model_class.new
      aggregate_failures do
        expect { instance.title_de }.to raise_error(NoMethodError)
        expect { instance.title_de? }.to raise_error(NoMethodError)
        expect { instance.send(:title_de=, "value", {}) }.to raise_error(NoMethodError)
      end
    end
  end

  context "locales set" do
    let(:model_class) do
      base_model_class.include described_class.new(:title, locales: [:cz, :de, :'pt-BR'])
    end

    it_behaves_like "locale accessor", :title, :cz
    it_behaves_like "locale accessor", :title, :de
    it_behaves_like "locale accessor", :title, :'pt-BR'

    it "raises NoMethodError if locale not in locales" do
      instance = model_class.new
      aggregate_failures do
        expect { instance.title_en }.to raise_error(NoMethodError)
        expect { instance.title_en? }.to raise_error(NoMethodError)
        expect { instance.send(:title_en=, "value", {}) }.to raise_error(NoMethodError)
      end
    end
  end
end
