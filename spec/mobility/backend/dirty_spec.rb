require "spec_helper"

describe Mobility::Backend::Dirty do
  let(:backend_class) do
    Class.new(Mobility::Backend::Null) do
      def read(locale, options = {})
        values[locale]
      end

      def write(locale, value, options = {})
        values[locale] = value
      end

      private

      def values
        @values ||= {}
      end
    end
  end

  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include Mobility
    Article.translates :title, backend: backend_class, dirty: true, cache: false
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      article = Article.new

      expect(article.title).to eq(nil)
      expect(article.changed?).to eq(false)
      expect(article.changed).to eq([])
      expect(article.changes).to eq({})

      article.title = "foo"
      expect(article.title).to eq("foo")
      expect(article.changed?).to eq(true)
      expect(article.changed).to eq(["title_en"])
      expect(article.changes).to eq({ "title_en" => [nil, "foo"] })
    end

    it "tracks changes in multiple locales" do
      article = Article.new

      expect(article.title).to eq(nil)

      article.title = "English title"

      expect(article.changed?).to eq(true)
      expect(article.changed).to eq(["title_en"])
      expect(article.changes).to eq({ "title_en" => [nil, "English title"] })

      Mobility.locale = :fr

      article.title = "Titre en Francais"
      expect(article.changed?).to eq(true)
      expect(article.changed).to match_array(["title_en", "title_fr"])
      expect(article.changes).to eq({ "title_en" => [nil, "English title"], "title_fr" => [nil, "Titre en Francais"] })
    end

    it "resets changes when locale is set to original value" do
      article = Article.new

      expect(article.changed?).to eq(false)

      article.title = "foo"
      expect(article.changed?).to eq(true)
      expect(article.changed).to eq(["title_en"])
      expect(article.changes).to eq({ "title_en" => [nil, "foo"] })

      article.title = nil
      expect(article.changed?).to eq(false)
      expect(article.changed).to eq([])
      expect(article.changes).to eq({})

      Mobility.with_locale(:fr) { article.title = "Titre en Francais" }

      expect(article.changed?).to eq(true)
      expect(article.changed).to eq(["title_fr"])
      expect(article.changes).to eq({ "title_fr" => [nil, "Titre en Francais"] })
    end
  end

  describe "suffix methods" do
    it "returns changes on attribute for current locale" do
      article = Article.create(title: "foo")
      article.title = "bar"
      expect(article.title_changed?).to eq(true)
      expect(article.title_change).to eq(["foo", "bar"])
      expect(article.title_was).to eq("foo")

      Mobility.locale = :fr
      expect(article.title_changed?).to eq(false)
      expect(article.title_change).to eq(nil)
      expect(article.title_was).to eq(nil)
    end
  end
end
