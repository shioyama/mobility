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
      Mobility.locale = :'pt-BR'
      article = Article.new

      aggregate_failures "before change" do
        expect(article.title).to eq(nil)
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([])
        expect(article.column_changes).to eq({})
      end

      aggregate_failures "set same value" do
        article.title = nil
        expect(article.title).to eq(nil)
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([])
        expect(article.column_changes).to eq({})
      end

      article.title = "foo"

      aggregate_failures "after change" do
        expect(article.title).to eq("foo")
        expect(article.column_changed?(:title)).to eq(true)
        expect(article.column_change(:title)).to eq([nil, "foo"])
        expect(article.changed_columns).to eq([:title_pt_br])
        expect(article.column_changes).to eq({ :title_pt_br => [nil, "foo"] })
      end
    end

    it "tracks previous changes in one locale" do
      article = Article.create(title: "foo")

      aggregate_failures do
        article.title = "bar"
        expect(article.column_changed?(:title)).to eq(true)

        article.save

        expect(article.column_changed?(:title)).to eq(false)
        expect(article.previous_changes).to eq({ :title_en => ["foo", "bar"]})
      end
    end

    it "tracks changes in multiple locales" do
      article = Article.new

      expect(article.title).to eq(nil)

      aggregate_failures "change in English locale" do
        article.title = "English title"

        expect(article.column_changed?(:title)).to eq(true)
        expect(article.changed_columns).to eq([:title_en])
        expect(article.column_changes).to eq({ :title_en => [nil, "English title"] })
      end

      aggregate_failures "change in French locale" do
        Mobility.locale = :fr

        article.title = "Titre en Francais"
        expect(article.column_changed?(:title)).to eq(true)
        expect(article.changed_columns).to match_array([:title_en, :title_fr])
        expect(article.column_changes).to eq({ title_en: [nil, "English title"], title_fr: [nil, "Titre en Francais"] })
      end
    end

    it "tracks previous changes in multiple locales" do
      article = Article.new
      article.title_en = "English title 1"
      article.title_fr = "Titre en Francais 1"
      article.save

      article.title = "English title 2"
      Mobility.locale = :fr
      article.title = "Titre en Francais 2"

      article.save

      expect(article.previous_changes).to eq({title_en: ["English title 1", "English title 2"],
                                              title_fr: ["Titre en Francais 1", "Titre en Francais 2"]})
    end

    it "resets changes when locale is set to original value" do
      article = Article.create(title: "foo")

      expect(article.column_changed?(:title)).to eq(false)

      aggregate_failures "after change" do
        article.title = "bar"
        expect(article.column_changed?(:title)).to eq(true)
        expect(article.changed_columns).to eq([:title_en])
        expect(article.column_changes).to eq({ title_en: ["foo", "bar"] })
      end

      aggregate_failures "after setting attribute back to original value" do
        article.title = "foo"
        expect(article.changed_columns).to eq([])
        expect(article.column_changes).to eq({})
        expect(article.title).to eq("foo")
      end

      aggregate_failures "changing value in different locale" do
        Mobility.with_locale(:fr) { article.title = "Titre en Francais" }

        expect(article.column_changed?(:title)).to eq(false)
        expect(article.changed_columns).to eq([:title_fr])
        expect(article.column_changes).to eq({ title_fr: [nil, "Titre en Francais"] })

        Mobility.locale = :fr
        expect(article.column_changed?(:title)).to eq(true)
      end
    end
  end

  describe "fallbacks compatiblity" do
    before do
      stub_const 'ArticleWithFallbacks', Class.new(Sequel::Model)
      ArticleWithFallbacks.class_eval do
        dataset = DB[:articles]
        include Mobility
      end
      ArticleWithFallbacks.translates :title, backend: backend_class, dirty: true, cache: false, fallbacks: { en: 'ja' }
    end

    it "does not compare with fallback value" do
      article = ArticleWithFallbacks.new

      aggregate_failures "before change" do
        expect(article.title).to eq(nil)
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([])
        expect(article.column_changes).to eq({})
      end

      aggregate_failures "set fallback locale value" do
        Mobility.with_locale(:ja) { article.title = "あああ" }
        expect(article.title).to eq("あああ")
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([:title_ja])
        expect(article.column_changes).to eq({ title_ja: [nil, "あああ"]})
        Mobility.with_locale(:ja) { expect(article.title).to eq("あああ") }
      end

      aggregate_failures "set value in current locale to same value" do
        article.title = nil
        expect(article.title).to eq("あああ")
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([:title_ja])
        expect(article.column_changes).to eq({ title_ja: [nil, "あああ"]})
      end

      aggregate_failures "set value in fallback locale to different value" do
        Mobility.with_locale(:ja) { article.title = "ばばば" }
        expect(article.title).to eq("ばばば")
        expect(article.column_changed?(:title)).to eq(false)
        expect(article.column_change(:title)).to eq(nil)
        expect(article.changed_columns).to eq([:title_ja])
        expect(article.column_changes).to eq({ title_ja: [nil, "ばばば"]})
      end

      aggregate_failures "set value in current locale to different value" do
        article.title = "Title"
        expect(article.title).to eq("Title")
        expect(article.column_changed?(:title)).to eq(true)
        expect(article.column_change(:title)).to eq(["ばばば", "Title"])
        expect(article.changed_columns).to match_array([:title_ja, :title_en])
        expect(article.column_changes).to eq({ title_ja: [nil, "ばばば"], title_en: ["ばばば", "Title"]})
      end
    end
  end
end
