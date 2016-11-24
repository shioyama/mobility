require 'spec_helper'

describe Mobility do
  it 'has a version number' do
    expect(Mobility::VERSION).not_to be nil
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
