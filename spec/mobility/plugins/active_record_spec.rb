require "spec_helper"

describe "Mobility::Plugins::ActiveRecord", orm: :active_record do
  include Helpers::Plugins

  plugin_setup do
    active_record
  end

  it "raises TypeError unless class is a subclass of ActiveRecord::Base" do
    klass = Class.new
    ar_class = Class.new(ActiveRecord::Base)

    expect { klass.include attributes }.to raise_error(TypeError, /should be a subclass of ActiveRecord\:\:Base/)
    expect { ar_class.include attributes }.not_to raise_error
  end
end if defined?(ActiveRecord)
