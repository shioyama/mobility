require "spec_helper"
require "mobility/plugins/fallthrough_accessors"

describe Mobility::Plugins::FallthroughAccessors do
  include Helpers::Plugins

  context "option value is truthy" do
    plugin_setup fallthrough_accessors: true
    it_behaves_like "locale accessor", :title, :en
    it_behaves_like "locale accessor", :title, :de
    it_behaves_like "locale accessor", :title, :'pt-BR'
    it_behaves_like "locale accessor", :title, :'ru'
  end

  context "option value is false" do
    plugin_setup fallthrough_accessors: false
    it "does not include instance of FallthroughAccessors into attributes class" do
      instance = model_class.new
      expect { instance.title_en }.to raise_error(NoMethodError)
      expect { instance.title_en? }.to raise_error(NoMethodError)
      expect { instance.send(:title_en=, "value", {}) }.to raise_error(NoMethodError)
    end
  end
end
