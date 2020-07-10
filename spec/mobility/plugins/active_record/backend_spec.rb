require "spec_helper"

describe "Mobility::Plugins::ActiveRecord::Backend", orm: :active_record do
  require "mobility/plugins/active_record/backend"

  include Helpers::Plugins

  plugin_setup do
    active_record_backend
  end

  describe "#load_backend" do
    context "backend with name exists in ActiveRecord namespace" do
      it "attempts to load active_record variant of backend" do
        expect(attributes.load_backend(:key_value)).to eq(Mobility::Backends::ActiveRecord::KeyValue)
      end
    end

    context "backend with name does not exist in ActiveRecord namespace" do
      it "raises LoadError on backend name" do
        expect {
          attributes.load_backend(:foo)
        }.to raise_error(LoadError, /mobility\/backends\/foo/)
      end
    end
  end
end if defined?(ActiveRecord)
