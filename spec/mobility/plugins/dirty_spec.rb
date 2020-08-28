require "spec_helper"
require "mobility/plugins/dirty"

describe Mobility::Plugins::Dirty, type: :plugin do
  plugin_setup

  context "dirty default option" do
    plugins :dirty

    it "requires fallthrough_accessors" do
      expect(translations).to have_plugin(:fallthrough_accessors)
    end
  end

  context "fallthrough accessors is falsey" do
    plugins do
      dirty true
      fallthrough_accessors false
    end

    it "emits warning" do
      expect { instance }.to output(
        /The Dirty plugin depends on Fallthrough Accessors being enabled,/
      ).to_stderr
    end
  end
end
