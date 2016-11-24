require 'spec_helper'

describe Mobility do
  it 'has a version number' do
    expect(Mobility::VERSION).not_to be nil
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
