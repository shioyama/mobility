require "spec_helper"

describe "Mobility::Plugins::Sequel", orm: :sequel, type: :plugin do
  plugins do
    sequel
  end

  it "raises TypeError unless class is a subclass of Sequel::Model" do
    klass = Class.new
    sequel_class = Class.new(Sequel::Model)

    expect { translates(klass) }.to raise_error(TypeError, /should be a subclass of Sequel\:\:Model/)
    expect { translates(sequel_class) }.not_to raise_error
  end
end
