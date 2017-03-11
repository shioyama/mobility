require "spec_helper"

describe Mobility::Configuration do
  subject { Mobility::Configuration.new }

  it "initializes default fallbacks to I18n::Locale::Fallbacks.new" do
    expect(subject.default_fallbacks).to be_a(I18n::Locale::Fallbacks)
  end

  it "initializes default accessor_locales to I18n.available_locales" do
    expect(subject.default_accessor_locales.call).to eq(I18n.available_locales)
  end

  it "sets default_backend to nil" do
    expect(subject.default_backend).to eq(nil)
  end
end
