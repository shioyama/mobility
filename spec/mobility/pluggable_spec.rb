require "spec_helper"

describe Mobility::Pluggable do
  include Helpers::Plugins

  define_plugins(:foo, :bar, :baz)

  it "dupes parent class defaults in descendants" do
    klass = Class.new(described_class)
    klass.plugin(:foo, default: 'foo')

    subclass = Class.new(klass)
    subclass.plugin(:bar, default: 'bar')

    expect(klass.defaults).to eq(foo: 'foo')
    expect(subclass.defaults).to eq(foo: 'foo', bar: 'bar')
  end

  it "overrides parent default in descendant if set" do
    klass = Class.new(described_class)
    klass.plugin(:foo, default: 'foo')

    subclass = Class.new(klass)
    subclass.plugin(:foo, default: 'foo2')

    expect(klass.defaults).to eq(foo: 'foo')
    expect(subclass.defaults).to eq(foo: 'foo2')
  end

  it "inherits parent default if default unset in descendant" do
    klass = Class.new(described_class)
    klass.plugin(:foo, default: 'foo')

    subclass = Class.new(klass)
    subclass.plugin(:foo)

    expect(klass.defaults).to eq(foo: 'foo')
    expect(subclass.defaults).to eq(foo: 'foo')
  end
end
