require "spec_helper"

describe Mobility::Plugins::AttributeMethods, orm: :active_record do
  include Helpers::Plugins
  plugin_setup attribute_methods: true

  let(:untranslated_attributes) do
    {
      "id" => nil,
      "slug" => nil,
      "published" => nil,
      "created_at" => nil,
      "updated_at" => nil
    }
  end
  let(:model_class) do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include(attributes)
    Article
  end

  describe "#translated_attributes" do
    it "returns hash of translated attribute names/values" do
      expect(backend).to receive(:read).once.with(Mobility.locale, any_args).and_return('foo')
      expect(instance.translated_attributes).to eq('title' => 'foo')
    end
  end

  describe "#attributes" do
    it "adds translated attributes to normal attributes" do
      expect(backend).to receive(:read).once.with(Mobility.locale, any_args).and_return('foo')
      expect(instance.attributes).to eq(untranslated_attributes.merge('title' => 'foo'))
    end
  end

  describe "#untranslated_attributes" do
    it "returns original value of attributes method" do
      expect(instance.untranslated_attributes).to eq(untranslated_attributes)
    end
  end
end if Mobility::Loaded::ActiveRecord
