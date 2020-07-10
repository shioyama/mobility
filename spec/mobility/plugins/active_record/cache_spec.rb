require "spec_helper"

describe "Mobility::Plugins::ActiveRecord::Cache", orm: :active_record do
  include Helpers::Plugins
  plugin_setup active_record: true, cache: true

  let(:model_class) do
    klass = Class.new(ActiveRecord::Base)
    klass.table_name = :articles
    klass
  end

  %w[changes_applied clear_changes_information].each do |method_name|
    it "clears backend cache after #{method_name}" do
      model_class.include attributes

      expect(instance.mobility_backends[:title]).to receive(:clear_cache).once
      instance.send(method_name)
    end

    it "does not change visibility of #{method_name}" do
      priv = model_class.private_method_defined?(method_name)
      model_class.include attributes

      expect(model_class.private_method_defined?(method_name)).to eq(priv)
    end
  end

  it "clears cache after reload" do
    model_class.include attributes

    instance = model_class.create
    if ::ActiveRecord::VERSION::MAJOR == 4
      expect(instance.mobility_backends[:title]).to receive(:clear_cache).at_least(1).time
    else
      expect(instance.mobility_backends[:title]).to receive(:clear_cache).once
    end
    instance.reload
  end
end
