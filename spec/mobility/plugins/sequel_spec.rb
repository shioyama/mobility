require "spec_helper"

describe "Mobility::Plugins::Sequel", orm: :sequel do
  include Helpers::Plugins

  plugin_setup do
    sequel
  end

  it "raises TypeError unless class is a subclass of Sequel::Model" do
    klass = Class.new
    sequel_class = Class.new(Sequel::Model)

    expect { klass.include attributes }.to raise_error(TypeError, /should be a subclass of Sequel\:\:Model/)
    expect { sequel_class.include attributes }.not_to raise_error
  end
end if defined?(Sequel)
