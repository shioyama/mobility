require "spec_helper"

describe Mobility::Configuration do
  subject { Mobility::Configuration.new }

  it "initializes default fallbacks to I18n::Locale::Fallbacks.new" do
    expect(subject.default_fallbacks).to be_a(I18n::Locale::Fallbacks)
  end

  it "initializes default accessor_locales to I18n.available_locales" do
    expect(subject.default_accessor_locales).to eq(I18n.available_locales)
  end

  it "sets default_backend to nil" do
    expect(subject.default_backend).to eq(nil)
  end

  describe "#default_accessor_locales=" do
    it "returns array of locales if assigned array" do
      subject.default_accessor_locales = [:en, :ja]
      expect(subject.default_accessor_locales).to eq([:en, :ja])
    end

    it "returned proc evaluated when called if assigned a proc" do
      @accessor_locales = [:en, :fr]
      subject.default_accessor_locales = lambda { @accessor_locales }
      expect(subject.default_accessor_locales).to eq([:en, :fr])
      @accessor_locales = [:en, :de]
      expect(subject.default_accessor_locales).to eq([:en, :de])
    end
  end

  describe "#default_options" do
    it "raises exception when reserved option keys are set" do
      aggregate_failures do
        %i[backend model_class].each do |reserved_key|
          expect {
            subject.default_options[reserved_key] = "value"
          }.to raise_error(Mobility::Configuration::ReservedOptionKey)
        end
      end
    end
  end
end
