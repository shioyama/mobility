require "spec_helper"

describe Mobility::Backend::Sequel::Dirty, orm: :sequel do
  let(:backend_class) do
    Class.new(Mobility::Backend::Null) do
      def read(locale, **options)
        values[locale]
      end

      def write(locale, value, **options)
        values[locale] = value
      end

      private

      def values
        @values ||= {}
      end
    end
  end

  before do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article.include Mobility
    Article.translates :title, backend: backend_class, dirty: true, cache: false
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      article = Article.new

      expect(article.title).to eq(nil)
      expect(article.column_changed?(:title)).to eq(false)
      expect(article.column_change(:title)).to eq(nil)
      expect(article.changed_columns).to eq([])
      expect(article.column_changes).to eq({})

      article.title = "foo"
      expect(article.title).to eq("foo")
      expect(article.column_changed?(:title)).to eq(true)
      expect(article.column_change(:title)).to eq([nil, "foo"])
      expect(article.changed_columns).to eq([:title_en])
      expect(article.column_changes).to eq({ :title_en => [nil, "foo"] })
    end

    it "tracks previous changes in one locale" do
      article = Article.create(title: "foo")

      article.title = "bar"
      expect(article.column_changed?(:title)).to eq(true)

      article.save

      expect(article.column_changed?(:title)).to eq(false)
      expect(article.previous_changes).to eq({ :title_en => ["foo", "bar"]})
    end

    it "tracks changes in multiple locales" do
      article = Article.new

      expect(article.title).to eq(nil)

      article.title = "English title"

      expect(article.column_changed?(:title)).to eq(true)
      expect(article.changed_columns).to eq([:title_en])
      expect(article.column_changes).to eq({ :title_en => [nil, "English title"] })

      Mobility.locale = :fr

      article.title = "Titre en Francais"
      expect(article.column_changed?(:title)).to eq(true)
      expect(article.changed_columns).to match_array([:title_en, :title_fr])
      expect(article.column_changes).to eq({ title_en: [nil, "English title"], title_fr: [nil, "Titre en Francais"] })
    end

    it "tracks previous changes in multiple locales" do
      article = Article.create(title_en: "English title 1", title_fr: "Titre en Francais 1")
      article.title = "English title 2"
      Mobility.locale = :fr
      article.title = "Titre en Francais 2"

      article.save

      expect(article.previous_changes).to eq({title_en: ["English title 1", "English title 2"],
                                              title_fr: ["Titre en Francais 1", "Titre en Francais 2"]})
    end

    pending "resets changes when locale is set to original value" do
      article = Article.create(title: "foo")

      expect(article.column_changed?(:title)).to eq(false)

      article.title = "bar"
      expect(article.column_changed?(:title)).to eq(true)
      expect(article.changed_columns).to eq([:title_en])
      expect(article.column_changes).to eq({ title_en: ["foo", "bar"] })

      article.title = "foo"
      expect(article.column_changed?(:title)).to eq(false)
      expect(article.changed_columns).to eq([])
      expect(article.column_changes).to eq({})

      Mobility.with_locale(:fr) { article.title = "Titre en Francais" }

      expect(article.column_changed?(:title)).to eq(true)
      expect(article.changed_columns).to eq([:title_fr])
      expect(article.column_changes).to eq({ title_fr: [nil, "Titre en Francais"] })
    end
  end
end
