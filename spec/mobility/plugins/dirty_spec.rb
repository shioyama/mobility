require "spec_helper"
require "mobility/plugins/dirty"

describe Mobility::Plugins::Dirty do
  include Helpers::Plugins
  plugin_setup dirty: true

  it "requires fallthrough_accessors" do
    expect(attributes).to have_plugin(:fallthrough_accessors)
  end
end
