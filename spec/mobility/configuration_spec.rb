require "spec_helper"

describe Mobility::Configuration do
  subject { Mobility::Configuration.new }

  it "sets default_backend to nil" do
    expect(subject.default_backend).to eq(nil)
  end

  describe "#plugin" do
    it "delegates to attributes_class#plugin" do
      expect(subject.translations_class).to receive(:plugin).with(:foo, these: 'params')
      subject.plugin :foo, these: 'params'
    end
  end
end
