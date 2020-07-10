require "spec_helper"
require "mobility/plugins/dirty"

describe Mobility::Plugins::Dirty do
  include Helpers::Plugins

  context "option value is truthy" do
    plugin_setup dirty: true

    it "does defines method_missing override" do
      model_class.include attributes
      expect(attributes.instance_methods(false)).to include(:method_missing)
    end
  end

  context "option value is falsey" do
    plugin_setup dirty: false

    it "does not define method_missing override" do
      model_class.include attributes
      expect(attributes.instance_methods(false)).not_to include(:method_missing)
    end
  end
end
