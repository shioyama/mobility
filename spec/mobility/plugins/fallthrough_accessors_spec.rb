require "spec_helper"

describe Mobility::Plugins::FallthroughAccessors do
  describe "when included into a class" do
    let(:model_class) do
      klass = Class.new do
        def title(**_); end
        def title?(**_); end
        def title=(_value, **_); end
      end
      klass.include described_class.new(:title)
      klass
    end

    it_behaves_like "locale accessor", :title, :en
    it_behaves_like "locale accessor", :title, :de
    it_behaves_like "locale accessor", :title, :'pt-BR'

    it "raises InvalidLocale if locale is not in I18n.available_locales" do
      expect { model_class.new.title_ru }.to raise_error(Mobility::InvalidLocale)
    end
  end

  describe ".apply" do
    let(:attributes) { instance_double(Mobility::Attributes, model_class: model_class, names: ["title"]) }
    let(:model_class) { Class.new }
    let(:fallthrough_accessors) { instance_double(described_class) }

    context "option value is truthy" do
      it "includes instance of FallthroughAccessors into attributes class" do
        expect(described_class).to receive(:new).twice.with("title").and_return(fallthrough_accessors)
        expect(model_class).to receive(:include).twice.with(fallthrough_accessors)
        described_class.apply(attributes, true)
        described_class.apply(attributes, [])
      end
    end

    context "option value is falsey" do
      it "does not include instance of FallthroughAccessors into attributes class" do
        expect(model_class).not_to receive(:include)
        described_class.apply(attributes, false)
        described_class.apply(attributes, nil)
      end
    end
  end
end
