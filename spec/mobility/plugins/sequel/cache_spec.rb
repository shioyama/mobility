require "spec_helper"

return unless defined?(Sequel)

require "mobility/plugins/sequel/cache"

describe Mobility::Plugins::Sequel::Cache, orm: :sequel, type: :plugin do
  plugins :sequel, :cache
  plugin_setup :title

  let(:model_class) do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article
  end

  it "clears backend cache after refresh" do
    model_class.include translations
    instance = model_class.create

    expect(instance.mobility_backends[:title]).to receive(:clear_cache).once
    instance.refresh
  end

  it "does not change visibility of refresh" do
    priv = model_class.private_method_defined?(:refresh)
    model_class.include translations

    expect(model_class.private_method_defined?(:refresh)).to eq(priv)
  end
end
