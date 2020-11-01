require "spec_helper"

describe Mobility::Pluggable do
  include Helpers::PluginSetup

  describe "#initialize" do
    define_plugins(:foo, :other)

    it "merges defaults into @options when initializing" do
      klass = Class.new(described_class)

      klass.plugin :foo, 'bar'
      klass.plugin :other

      pluggable = klass.new(other: 'param')
      expect(pluggable.options).to eq(foo: 'bar', other: 'param')
    end

    it "raises InvalidOptionKey error if no plugin is configured for an options key" do
      klass = Class.new(described_class)

      expect {
        klass.new(foo: 'foo', bar: 'bar')
      }.to raise_error(Mobility::Pluggable::InvalidOptionKey, "No plugin configured for these keys: foo, bar.")
    end
  end

  describe "subclassing" do
    define_plugins(:foo, :bar, :baz)

    it "dupes parent class defaults in descendants" do
      klass = Class.new(described_class)
      klass.plugin(:foo, 'foo')

      subclass = Class.new(klass)
      subclass.plugin(:bar, 'bar')

      expect(klass.defaults).to eq(foo: 'foo')
      expect(subclass.defaults).to eq(foo: 'foo', bar: 'bar')
    end

    it "overrides parent default in descendant if set" do
      klass = Class.new(described_class)
      klass.plugin(:foo, 'foo')

      subclass = Class.new(klass)
      subclass.plugin(:foo, 'foo2')

      expect(klass.defaults).to eq(foo: 'foo')
      expect(subclass.defaults).to eq(foo: 'foo2')
    end

    it "inherits parent default if default unset in descendant" do
      klass = Class.new(described_class)
      klass.plugin(:foo, 'foo')

      subclass = Class.new(klass)
      subclass.plugin(:foo)

      expect(klass.defaults).to eq(foo: 'foo')
      expect(subclass.defaults).to eq(foo: 'foo')
    end
  end
end
