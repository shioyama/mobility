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

  describe "uniqueness validation" do
    before do
      opts = uniqueness_opts
      Article.class_eval do
        extend Mobility
        translates :title, backend: :null
        validates :title, uniqueness: opts
      end
    end
    let(:article) do
      Article.new
    end

    context "case_sensitive = false" do
      let(:uniqueness_opts) { { case_sensitive: false } }

      it "ignores option and emits warning" do
        expect { expect(article.valid?).to eq(true) }.to output(
          /#{%{
WARNING: The Mobility uniqueness validator for translated attributes does not
support case-insensitive validation. This option will be ignored.}}/).to_stderr
      end
    end

    context "case_sensitive = nil" do
      let(:uniqueness_opts) { { } }

      it "does not emit warning" do
        expect { expect(article.valid?).to eq(true) }.not_to output.to_stderr
      end
    end

    context "case_sensitive = true" do
      let(:uniqueness_opts) { { case_sensitive: true } }

      it "does not emit warning" do
        expect { expect(article.valid?).to eq(true) }.not_to output.to_stderr
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
