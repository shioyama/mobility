require "spec_helper"

describe Mobility::ActiveRecord, orm: :active_record do
  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include Mobility::ActiveRecord
  end

  describe ".i18n" do
    it "extends class with .i18n scope method" do
      scope = double('scope')
      expect(Article).to receive(:all).and_return(scope)

      expect(Article.i18n).to eq(scope)
    end
  end

  describe "#translated_attribute_names" do
    it "delegates to class" do
      Article.instance_eval do
        def translated_attribute_names; end
      end
      expect(Article).to receive(:translated_attribute_names).and_return(["foo"])
      expect(Article.new.translated_attribute_names).to eq(["foo"])
    end
  end
end if Mobility::Loaded::ActiveRecord
