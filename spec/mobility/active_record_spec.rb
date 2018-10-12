require "spec_helper"

describe Mobility::ActiveRecord, orm: :active_record do
  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include Mobility::ActiveRecord
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

  # regression spec for https://github.com/shioyama/mobility/issues/258
  describe "name error" do
    it "resolves ActiveRecord to ::ActiveRecord in model class" do
      aggregate_failures do
        expect(Post.instance_eval("ActiveRecord")).to eq(::ActiveRecord)
        expect(Post.class_eval("ActiveRecord")).to eq(::ActiveRecord)
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
