require "spec_helper"

describe Mobility::Backend::ActiveRecord::KeyValue, orm: :active_record do
  extend Helpers::ActiveRecord

  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.class_eval do
      include Mobility
      translates :title, :content, backend: :key_value, cache: false
      translates :subtitle, backend: :key_value
    end
  end

  include_accessor_examples "Article"

  describe "Backend methods" do
    before { %w[foo bar baz].each { |slug| Article.create!(slug: slug) } }
    let(:article) { Article.find_by(slug: "baz") }
    let(:title_backend) { article.title_translations }
    let(:content_backend) { article.content_translations }

    subject { article }

    describe "#read" do
      before do
        [
          { key: "title", value: "New Article", locale: "en", translatable: article },
          { key: "title", value: "新規記事", locale: "ja", translatable: article },
          { key: "content", value: "Once upon a time...", locale: "en", translatable: article },
          { key: "content", value: "昔々あるところに…", locale: "ja", translatable: article }
        ].each { |attrs| Mobility::ActiveRecord::TextTranslation.create!(attrs) }
      end

      it "returns attribute in locale from translations table" do
        aggregate_failures do
          expect(title_backend.read(:en)).to eq("New Article")
          expect(content_backend.read(:en)).to eq("Once upon a time...")
          expect(title_backend.read(:ja)).to eq("新規記事")
          expect(content_backend.read(:ja)).to eq("昔々あるところに…")
        end
      end

      it "returns nil if no translation exists" do
        expect(title_backend.read(:de)).to eq(nil)
      end

      it "builds translation if no translation exists" do
        expect {
          title_backend.read(:de)
        }.to change(subject.send(:mobility_text_translations), :size).by(1)
      end

      describe "reading back written attributes" do
        before do
          title_backend.write(:en, "Changed Article Title")
        end

        it "returns changed value" do
          expect(title_backend.read(:en)).to eq("Changed Article Title")
        end
      end
    end

    describe "#write" do
      context "no translation for locale exists" do
        it "creates translation for locale" do
          expect {
            title_backend.write(:en, "New Article")
          }.to change(subject.send(:mobility_text_translations), :size).by(1)

          expect { subject.save! }.to change(Mobility::ActiveRecord::TextTranslation, :count).by(1)
        end

        it "assigns attributes to translation" do
          title_backend.write(:en, "New Article")

          translation = subject.send(:mobility_text_translations).first

          aggregate_failures do
            expect(translation.key).to eq("title")
            expect(translation.value).to eq("New Article")
            expect(translation.translatable).to eq(subject)
          end
        end
      end

      context "translation for locale exists" do
        before do
          Mobility::ActiveRecord::TextTranslation.create!(
            key: "title",
            value: "foo",
            locale: "en",
            translatable: subject
          )
        end

        it "does not create new translation for locale" do
          expect {
            title_backend.write(:en, "New Article")
          }.not_to change(subject.send(:mobility_text_translations), :size)
        end

        it "updates value attribute on existing translation" do
          title_backend.write(:en, "New New Article")
          subject.save!
          subject.reload

          translation = subject.send(:mobility_text_translations).first

          aggregate_failures do
            expect(translation.key).to eq("title")
            expect(translation.value).to eq("New New Article")
            expect(translation.translatable).to eq(subject)
          end
        end

        it "removes persisted translation if assigned nil when record is saved" do
          expect(Mobility::ActiveRecord::TextTranslation.count).to eq(1)
          expect {
            title_backend.write(:en, nil)
          }.not_to change(subject.send(:mobility_text_translations), :count)

          expect {
            subject.save!
          }.to change(subject.send(:mobility_text_translations), :count).by(-1)

          expect(Mobility::ActiveRecord::TextTranslation.count).to eq(0)
        end

        it "removes unpersisted translation if value is nil when record is saved" do
          article = Article.find_by(slug: "foo")
          expect(article.title).to eq(nil)
          article.title = ""
          expect(article.mobility_text_translations.size).to eq(1)
          article.save
          expect(article.mobility_text_translations.size).to eq(0)
        end
      end
    end
  end

  describe "translations association" do
    it "limits association to translations with keys matching attributes" do
      # This limits the results returned by the association to only those whose keys match the set of
      # translated attributes we have defined. This matters if, say, we save some translations, then change
      # the translated attributes for the model; we should only see the new translations, not the ones
      # created earlier with different keys.
      article = Article.create(title: "Article", subtitle: "Article subtitle", content: "Content")
      translation = Mobility::ActiveRecord::TextTranslation.create(key: "foo", value: "bar", locale: "en", translatable: article)
      article = Article.first

      aggregate_failures do
        expect(article.mobility_text_translations).not_to include(translation)
        expect(article.mobility_text_translations.count).to eq(3)
      end
    end
  end

  describe "creating a new record with translations" do
    it "creates record and translation in current locale" do
      Mobility.locale = :en
      article = Article.create(title: "New Article", content: "Once upon a time...")

      aggregate_failures do
        expect(Article.count).to eq(1)
        expect(Mobility::ActiveRecord::TextTranslation.count).to eq(2)
        expect(article.send(:mobility_text_translations).size).to eq(2)
        expect(article.title).to eq("New Article")
        expect(article.content).to eq("Once upon a time...")
      end
    end

    it "creates translations for other locales" do
      Mobility.locale = :en
      article = Article.create(title: "New Article", content: "Once upon a time...")

      aggregate_failures "in one locale" do
        expect(article.mobility_text_translations.count).to eq(2)
      end

      aggregate_failures "in another locale" do
        Mobility.locale = :ja
        expect(article.title).to eq(nil)
        expect(article.content).to eq(nil)
        article.update_attributes!(title: "新規記事", content: "昔々あるところに…")
        expect(article.title).to eq("新規記事")
        expect(article.content).to eq("昔々あるところに…")
        expect(Article.count).to eq(1)
        expect(Mobility::ActiveRecord::TextTranslation.count).to eq(4)
        expect(article.send(:mobility_text_translations).size).to eq(4)
      end
    end

    it "builds nil translations when reading but does not save them" do
      Mobility.locale = :en
      article = Article.create(title: "New Article")
      Mobility.locale = :ja
      article.title

      aggregate_failures do
        expect(article.send(:mobility_text_translations).size).to eq(2)
        article.save
        expect(article.title).to be_nil
        expect(article.reload.send(:mobility_text_translations).size).to eq(1)
      end
    end
  end

  context "with separate string and text translations" do
    before do
      Article.class_eval do
        translates :short_title, backend: :key_value, class_name: Mobility::ActiveRecord::StringTranslation, association_name: :mobility_string_translations
      end
    end

    it "saves translations correctly" do
      article = Article.create(title: "foo title", short_title: "bar short title")

      aggregate_failures "setting attributes" do
        expect(article.title).to eq("foo title")
        expect(article.short_title).to eq("bar short title")
      end

      aggregate_failures "after reloading" do
        article = Article.first
        expect(article.title).to eq("foo title")
        expect(article.short_title).to eq("bar short title")

        text = Mobility::ActiveRecord::TextTranslation.first
        expect(text.value).to eq("foo title")

        string = Mobility::ActiveRecord::StringTranslation.first
        expect(string.value).to eq("bar short title")
      end
    end
  end

  describe ".configure!" do
    it "sets association_name and class_name from string type" do
      options = { type: :string }
      described_class.configure!(options)
      expect(options).to eq({
        type: :string,
        class_name: Mobility::ActiveRecord::StringTranslation,
        association_name: :mobility_string_translations
      })
    end

    it "sets association_name and class_name from text type" do
      options = { type: :text }
      described_class.configure!(options)
      expect(options).to eq({
        type: :text,
        class_name: Mobility::ActiveRecord::TextTranslation,
        association_name: :mobility_text_translations
      })
    end

    it "raises ArgumentError if type is not string or text" do
      expect { described_class.configure!(type: :foo) }.to raise_error(ArgumentError)
    end

    it "sets default association_name and class_name" do
      options = {}
      described_class.configure!(options)
      expect(options).to eq({
        association_name: :mobility_text_translations,
        class_name: Mobility::ActiveRecord::TextTranslation
      })
    end
  end

  describe "mobility scope (.i18n)" do
    include_querying_examples('Post')

    describe "joins" do
      it "uses inner join for WHERE queries" do
        expect(Post.i18n.where(title: "foo").to_sql).not_to match(/OUTER/)
      end

      it "does not use OUTER JOIN with .not" do
        # we don't need an OUTER join when matching nil values since
        # we're searching for negative matches
        expect(Post.i18n.where.not(title: nil).to_sql).not_to match /OUTER/
      end
    end

    context "model with two translated attributes on different tables" do
      before do
        Article.class_eval do
          translates :short_title, backend: :key_value, class_name: Mobility::ActiveRecord::StringTranslation, association_name: :mobility_string_translations
        end
        @article1 = Article.create(title: "foo post", short_title: "bar short 1")
        @article2 = Article.create(title: "foo post", short_title: "bar short 2")
        @article3 = Article.create(                   short_title: "bar short 1")
      end

      it "returns correct result when querying on multiple tables" do
        aggregate_failures do
          expect(Article.i18n.where(title: "foo post", short_title: "bar short 2")).to eq([@article2])
          expect(Article.i18n.where(title: nil, short_title: "bar short 2")).to eq([])
          expect(Article.i18n.where(title: nil, short_title: "bar short 1")).to eq([@article3])
        end
      end
    end

    describe "Subclassing ActiveRecord::QueryMethods::WhereChain" do
      it "extends Post.mobility_where_chain to handle translated attributes without creating memory leak" do
        Post.i18n # call once to ensure class is defined
        expect(Post.mobility_where_chain.ancestors).to include(::ActiveRecord::QueryMethods::WhereChain)
        expect { Post.i18n.where.not(title: "foo") }.not_to change(Post.mobility_where_chain, :ancestors)
      end
    end
  end

  describe "Model.i18n.find_by_<translated attribute>" do
    it "finds correct translation if exists in current locale" do
      Mobility.locale = :ja
      article = Article.create(title: "タイトル")
      expect(Article.i18n.find_by_title("タイトル")).to eq(article)
      expect(Article.i18n.find_by_title("foo")).to be_nil
    end

    it "returns nil if no matching translation exists in this locale" do
      Mobility.locale = :ja
      article = Article.create(title: "タイトル")
      Mobility.locale = :en
      expect(Article.i18n.find_by_title("タイトル")).to eq(nil)
      expect(Article.i18n.find_by_title("foo")).to be_nil
    end

    it "works on a scope" do
      Mobility.locale = :ja
      article1 = Article.create(title: "タイトル")
      Mobility.locale = :en
      article2 = Article.create(title: "title")
      Mobility.with_locale(:ja) do
        expect(Article.i18n.all.find_by_title("タイトル")).to eq(article1)
      end
    end
  end
end
