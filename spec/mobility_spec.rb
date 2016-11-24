require 'spec_helper'

describe Mobility do
  it 'has a version number' do
    expect(Mobility::VERSION).not_to be nil
  end

  describe "including Mobility in class" do
    let!(:model) do
      model = stub_const 'MyModel', Class.new
      model.class_eval do
        def attributes
          { "foo" => "bar" }
        end
      end
      model
    end

    context "with no translated attributes" do
      it "does not include Attributes into model class" do
        expect(Mobility::Attributes).not_to receive(:new)
        model.include Mobility
      end
    end

    context "with translated attributes" do
      it "includes backend module into model class" do
        expect(Mobility::Attributes).to receive(:new).and_call_original
        model.include Mobility
        model.translates :title, backend: :null, foo: :bar
        backend_module = model.ancestors.find { |a| a.class == Mobility::Attributes }
        expect(backend_module).not_to be_nil
        expect(backend_module.attributes).to eq ["title"]
        expect(backend_module.options).to eq("foo" => :bar)
      end
    end
  end

  describe '.with_locale' do
    def perform_with_locale(locale)
      Thread.new do
        Mobility.with_locale(locale) do
          Thread.pass
          expect(locale).to eq(Mobility.locale)
        end
      end
    end

    it 'sets locale in a single thread' do
      perform_with_locale(:en).join
    end

    it 'sets independent locales in multiple threads' do
      threads = []
      threads << perform_with_locale(:en)
      threads << perform_with_locale(:fr)
      threads << perform_with_locale(:de)
      threads << perform_with_locale(:cz)
      threads << perform_with_locale(:pl)

      threads.each(&:join)
    end

    it "returns result" do
      expect(Mobility.with_locale(:ja) { |locale| "returned-#{locale}" }).to eq("returned-ja")
    end

    context "something blows up" do
      it "sets locale back" do
        Mobility.with_locale(:ja) { raise StandardError } rescue StandardError
        expect(Mobility.locale).to eq(:en)
      end
    end
  end

  describe '.config' do
    it 'initializes a new configuration' do
      expect(Mobility.config).to be_a(Mobility::Configuration)
    end

    it 'memoizes configuration' do
      expect(Mobility.config).to be(Mobility.config)
    end
  end

  it { should delegate_method(:default_fallbacks).to(:config) }
end
