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
end if Mobility::Loaded::ActiveRecord
