require "spec_helper"
require "mobility/plugins/locale_accessors"

describe Mobility::Plugins::LocaleAccessors do
  let(:attributes) do
    Mobility::Attributes.new(:title, backend: :null).tap do |attributes|
      described_class.apply(attributes, option)
    end
  end
  let(:model_class) { Class.new.include attributes }

  describe "when included into a class" do
    context "with locales set" do
      let(:option) { [:cz, :de, :'pt-BR'] }

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

      it "warns locale option will be ignored if called with locale" do
        instance = model_class.new
        warning_message = /locale passed as option to locale accessor will be ignored/
        expect(instance).to receive(:title).with(locale: :cz).and_return("foo")
        expect { expect(instance.title_cz(locale: :en)).to eq("foo") }.to output(warning_message).to_stderr
        expect(instance).to receive(:title?).with(locale: :cz).and_return(true)
        expect { expect(instance.title_cz?(locale: :en)).to eq(true) }.to output(warning_message).to_stderr
        expect(instance).to receive(:title=).with("new foo", locale: :cz)
        expect { instance.send(:title_cz=, "new foo", locale: :en)}.to output(warning_message).to_stderr
      end
    end

    context "with option = true" do
      let(:option) { true }

      it "defines locale accessors for all locales in I18n.available_locales" do
        methods = model_class.instance_methods
        I18n.available_locales.each do |locale|
          expect(methods).to include(:"title_#{Mobility.normalize_locale(locale)}")
          expect(methods).to include(:"title_#{Mobility.normalize_locale(locale)}?")
          expect(methods).to include(:"title_#{Mobility.normalize_locale(locale)}=")
        end
      end
    end

    describe "super: true" do
      let(:option) { [:en] }

      it "calls super of locale accessor method" do
        spy = double("model")
        klass = Class.new
        mod = Module.new do
          define_method :title_en do
            spy.title_en
          end
          define_method :title_en? do
            spy.title_en?
          end
          define_method :title_en= do |value|
            spy.title_en = value
          end
        end
        klass.include mod
        klass.include attributes

        instance = klass.new

        aggregate_failures do
          expect(spy).to receive(:title_en).and_return("model foo")
          expect(instance.title_en(super: true)).to eq("model foo")

          expect(spy).to receive(:title_en?).and_return(true)
          expect(instance.title_en?(super: true)).to eq(true)

          expect(spy).to receive(:title_en=).with("model foo")
          instance.send(:title_en=, "model foo", super: true)
        end
      end
    end
  end
end
