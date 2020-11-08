require "spec_helper"
require "mobility/plugins/attributes"

describe Mobility::Plugins::Attributes, type: :plugin do
  let(:translations_class) do
    Class.new(Mobility::Pluggable).tap do |translations_class|
      translations_class.plugin :attributes
    end
  end

  describe "#names" do
    it "returns arguments passed to initialize" do
      translations = translations_class.new("title", "content")
      expect(translations.names).to eq(["title", "content"])
    end
  end

  describe "#inspect" do
    it "includes backend name and attribute names" do
      translations = translations_class.new("title", "content")
      expect(translations.inspect).to eq("#<Translations @names=title, content>")
    end
  end

  describe ".mobility_attributes" do
    it "returns attributes included in one of multiple pluggable modules" do
      translations1 = translations_class.new("title", "content")
      translations2 = translations_class.new("author")
      klass = Class.new
      klass.include translations1
      klass.include translations2

      expect(klass.mobility_attributes).to eq(%w[title content author])
    end
  end

  describe ".mobility_attribute?" do
    it "returns true if name is an attribute" do
      translations = translations_class.new("title", "content")
      klass = Class.new
      klass.include translations

      expect(klass.mobility_attribute?("title")).to eq(true)
      expect(klass.mobility_attribute?("content")).to eq(true)
      expect(klass.mobility_attribute?("foo")).to eq(false)
    end

    it "returns true if name is included one of multiple pluggable modules" do
      translations1 = translations_class.new("title", "content")
      translations2 = translations_class.new("author")
      klass = Class.new
      klass.include translations1
      klass.include translations2

      expect(klass.mobility_attribute?("title")).to eq(true)
      expect(klass.mobility_attribute?("content")).to eq(true)
      expect(klass.mobility_attribute?("author")).to eq(true)
      expect(klass.mobility_attribute?("foo")).to eq(false)
    end
  end

  describe "inheritance" do
    it "inherits mobility attributes from parent" do
      mod1 = translations_class.new("title", "content")
      klass1 = Class.new
      klass1.include mod1

      klass2 = Class.new(klass1)

      expect(klass1.mobility_attributes).to match_array(%w[title content])
      expect(klass2.mobility_attributes).to match_array(%w[title content])

      mod2 = translations_class.new("author")
      klass2.include mod2

      expect(klass1.mobility_attributes).to match_array(%w[title content])
      expect(klass2.mobility_attributes).to match_array(%w[title content author])
    end

    it "freezes inherited attributes to ensure they are not changed after subclassing" do
      mod1 = translations_class.new("title")
      stub_const("Foo", Class.new)
      klass1 = Foo
      klass1.include mod1

      Class.new(klass1)
      expect(klass1.mobility_attributes).to be_frozen

      mod2 = translations_class.new("content")
      expect {
        klass1.include mod2
      }.to raise_error(Mobility::Plugins::Attributes::FrozenAttributesError,
                       "Attempting to translate these attributes on Foo, which has already been subclassed: content.")
    end
  end
end
