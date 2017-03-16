require "spec_helper"

describe Mobility::Backend::Fallbacks do
  let(:backend_class) do
    backend_class = stub_const 'MyBackend', Class.new
    backend_class.include(Mobility::Backend)
    backend_class.class_eval do
      def read(locale, **options)
        {
          "title" => {
            :'de-DE' => "foo",
            :'jp' => "フー",
            :'pt' => ""
          }
        }[attribute][locale]
      end
    end
    backend_class = Class.new(backend_class).include(described_class)
    backend_class
  end
  let(:object) { (stub_const 'MobilityModel', Class.new).include(Mobility).new }

  subject do
    backend_class.new(object, "title", fallbacks: { :'en-US' => 'de-DE', :pt => 'de-DE' })
  end

  it "returns value when value is not nil" do
    expect(subject.read(:"jp")).to eq("フー")
  end

  it "falls through to fallback locale when value is nil" do
    expect(subject.read(:"en-US")).to eq("foo")
  end

  it "falls through to fallback locale when value is blank" do
    expect(subject.read(:pt)).to eq("foo")
  end

  it "returns nil when no fallback is found" do
    expect(subject.read(:"fr")).to eq(nil)
  end

  it "returns nil when fallbacks: false option is passed" do
    expect(subject.read(:"en-US", fallback: false)).to eq(nil)
  end

  it "uses locale passed in as value of fallback option when present" do
    expect(subject.read(:"en-US", fallback: :jp)).to eq("フー")
  end

  it "uses array of locales passed in as value of fallback options when present" do
    expect(subject.read(:"en-US", fallback: [:es, :'de-DE'])).to eq("foo")
  end
end
