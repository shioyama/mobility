require "spec_helper"

return unless defined?(Sequel)

require "mobility/plugins/sequel/backend"

describe Mobility::Plugins::Sequel::Backend, orm: :sequel, type: :plugin do
  plugins :sequel_backend
  plugin_setup

  describe "#load_backend" do
    context "backend with name exists in Sequel namespace" do
      it "attempts to load sequel variant of backend" do
        expect(translations.load_backend(:key_value)).to eq(Mobility::Backends::Sequel::KeyValue)
      end
    end

    context "backend with name does not exist in Sequel namespace" do
      it "raises LoadError on backend name" do
        expect {
          translations.load_backend(:foo)
        }.to raise_error(LoadError, /mobility\/backends\/foo/)
      end
    end
  end
end
