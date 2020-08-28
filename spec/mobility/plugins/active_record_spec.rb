require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Plugins::ActiveRecord", orm: :active_record, type: :plugin do
  plugins :active_record

  it "raises TypeError unless class is a subclass of ActiveRecord::Base" do
    klass = Class.new
    ar_class = Class.new(ActiveRecord::Base)

    expect { translates(klass) }.to raise_error(TypeError, /should be a subclass of ActiveRecord\:\:Base/)
    expect { translates(ar_class) }.not_to raise_error
  end
end
