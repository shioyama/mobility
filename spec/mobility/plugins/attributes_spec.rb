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
end
