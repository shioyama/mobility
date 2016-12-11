require "spec_helper"

describe Mobility::Backend::Dirty, orm: :active_record do
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

    it "tracks previous changes in one locale" do
      article = Article.create(title: "foo")

      article.title = "bar"
      expect(article.changed?).to eq(true)

      article.save

      expect(article.changed?).to eq(false)
      expect(article.previous_changes).to eq({ "title_en" => ["foo", "bar"]})
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

    it "tracks previous changes in multiple locales" do
      article = Article.create(title_en: "English title 1", title_fr: "Titre en Francais 1")
      article.title = "English title 2"
      Mobility.locale = :fr
      article.title = "Titre en Francais 2"

      article.save

      expect(article.previous_changes).to eq({"title_en" => ["English title 1", "English title 2"],
                                              "title_fr" => ["Titre en Francais 1", "Titre en Francais 2"]})
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
    it "defines suffix methods on translated attribute" do
      article = Article.create(title: "foo")
      article.title = "bar"
      expect(article.title_changed?).to eq(true)
      expect(article.title_change).to eq(["foo", "bar"])
      expect(article.title_was).to eq("foo")

      article.save
      expect(article.title_previously_changed?).to eq(true)
      expect(article.title_previous_change).to eq(["foo", "bar"])

      expect(article.title_changed?).to eq(false)
      article.title_will_change!
      expect(article.title_changed?).to eq(true)
    end

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

  describe "resetting original values hash on actions" do
    shared_examples_for "resets on model action" do |action|
      it "resets changes when model on #{action}" do
        article = Article.create

        article.title = "foo"
        expect(article.changes).to eq({ "title_en" => [nil, "foo"] })

        article.send(action)

        # bypass the dirty module and set the variable directly
        article.title_translations.instance_variable_set(:@values, { :en => "bar" })

        expect(article.title).to eq("bar")
        expect(article.changes).to eq({})

        article.title = nil
        expect(article.changes).to eq({ "title_en" => ["bar", nil]})
      end
    end

    it_behaves_like "resets on model action", :save
    it_behaves_like "resets on model action", :reload
  end
end
