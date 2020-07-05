require "spec_helper"
require "mobility/plugins/backend_reader"

describe Mobility::Plugins::BackendReader do
  include Helpers::Plugins

  context "with default format string" do
    plugin_setup() { backend_reader }

    it "defines <attr>_backend methods mapping to backend instance for <attr>" do
      expect(instance.respond_to?(:title_backend)).to eq(true)
      expect(instance.title_backend).to eq(backend)
    end
  end

  context "with custom format string" do
    plugin_setup() { backend_reader default: "%s_translations" }

    it "defines backend reader methods with custom format string" do
      expect(instance.respond_to?(:title_translations)).to eq(true)
      expect(instance.respond_to?(:title_backend)).to eq(false)
      expect(instance.title_translations).to eq(backend)
    end
  end

  context "with true as format string" do
    plugin_setup() { backend_reader default: true }

    it "defines backend reader methods with default format string" do
      expect(instance.respond_to?(:title_backend)).to eq(true)
      expect(instance.title_backend).to eq(backend)
    end
  end

  context "with falsey format string" do
    plugin_setup() { backend_reader default: false }

    it "does not define backend reader methods" do
      expect(instance.respond_to?(:title_backend)).to eq(false)
      expect { instance.title_backend }.to raise_error(NoMethodError)
    end
  end
end
