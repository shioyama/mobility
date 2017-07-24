require "spec_helper"

describe Mobility::Backend::ActiveRecord::Table, orm: :active_record do
  extend Helpers::ActiveRecord

  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include Mobility
  end

  context "without cache" do
    before { Article.translates :title, :content, backend: :table, cache: false }
    include_accessor_examples "Article"
  end

  context "with cache" do
    before { Article.translates :title, :content, backend: :table, cache: true }
    include_accessor_examples "Article"

    it "resets model translations cache when backend cache is cleared" do
      article = Article.new
      title_backend = article.mobility_backend_for("title")
      content_backend = article.mobility_backend_for("content")
      title_backend.read(:en)
      expect(article.instance_variable_get(:@__mobility_model_translations_cache).size).to eq(1)
      content_backend.read(:en)
      expect(article.instance_variable_get(:@__mobility_model_translations_cache).size).to eq(1)
      content_backend.read(:ja)
      expect(article.instance_variable_get(:@__mobility_model_translations_cache).size).to eq(2)
      content_backend.send(:clear_cache)
      expect(article.instance_variable_get(:@__mobility_model_translations_cache).size).to eq(0)
    end
  end

  # Using Article to test separate backends with separate tables fails
  # when these specs are run together with other specs, due to code
  # assigning subclasses (Article::Translation, Article::FooTranslation).
  # Maybe an issue with RSpec const stubbing.
  context "attributes defined separately" do
    include_accessor_examples "MultitablePost", :title, :foo
    include_querying_examples "MultitablePost", :title, :foo
  end

  describe "Backend methods" do
    before do
      Article.translates :title, :content, backend: :table, cache: false
      %w[foo bar baz].each { |slug| Article.create!(slug: slug) }
    end
    let(:article) { Article.find_by(slug: "baz") }
    let(:title_backend) { article.mobility_backend_for("title") }
    let(:content_backend) { article.mobility_backend_for("content") }

    subject { article }

    describe "#read" do
      before do
        [
          { locale: "en", title: "New Article", content: "Once upon a time...", translated_model: article },
          { locale: "ja", title: "新規記事", content: "昔々あるところに…", translated_model: article }
        ].each { |attrs| Article::Translation.create!(attrs) }
      end

      it "returns attribute in locale from model translations table" do
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
        }.to change(subject.send(:mobility_model_translations), :size).by(1)
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
          }.to change(subject.send(:mobility_model_translations), :size).by(1)

          expect { subject.save! }.to change(Article::Translation, :count).by(1)
        end

        it "assigns attributes to translation" do
          title_backend.write(:en, "New Article")
          content_backend.write(:en, "Lorum ipsum...")

          translation = subject.send(:mobility_model_translations).first

          aggregate_failures do
            expect(translation.title).to eq("New Article")
            expect(translation.content).to eq("Lorum ipsum...")
            expect(translation.translated_model).to eq(subject)
          end
        end
      end

      context "translation for locale exists" do
        before do
          Article::Translation.create!(
            title: "foo",
            locale: "en",
            translated_model: subject
          )
        end

        it "does not create new translation for locale" do
          expect {
            title_backend.write(:en, "New Article")
          }.not_to change(subject.send(:mobility_model_translations), :size)
        end

        it "updates value attribute on existing translation" do
          title_backend.write(:en, "New New Article")
          subject.save!
          subject.reload

          translation = subject.send(:mobility_model_translations).first

          aggregate_failures do
            expect(translation.title).to eq("New New Article")
            expect(translation.translated_model).to eq(subject)
          end
        end
      end
    end
  end

  describe "mobility scope (.i18n)" do
    before { Article.translates :title, :content, backend: :table, cache: false }
    include_querying_examples('Article')
    include_validation_examples('Article')

    describe "joins" do
      it "uses inner join for WHERE queries if query has at least one non-null attribute" do
        expect(Article.i18n.where(title: "foo", content: nil).to_sql).not_to match(/OUTER/)
      end

      it "does not use OUTER JOIN with .not" do
        # we don't need an OUTER join when matching nil values since
        # we're searching for negative matches
        expect(Article.i18n.where.not(title: nil).to_sql).not_to match /OUTER/
      end
    end
  end

  describe "Model.i18n.find_by_<translated attribute>" do
    before { Article.translates :title, backend: :table, cache: false }

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
end if Mobility::Loaded::ActiveRecord
