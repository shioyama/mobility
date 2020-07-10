require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Table", orm: :active_record do
  require "mobility/backends/active_record/table"
  extend Helpers::ActiveRecord

  before do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, 'Article'
  end

  context "without cache" do
    before { Article.translates :title, :content, backend: :table, cache: false }
    include_accessor_examples "Article"
    include_dup_examples "Article"
    include_cache_key_examples "Article"

    it "finds translation on every read/write" do
      article = Article.new
      title_backend = backend_for(article, :title)
      expect(title_backend.model.send(title_backend.association_name)).to receive(:find).thrice.and_call_original
      title_backend.write(:en, "foo")
      title_backend.write(:en, "bar")
      expect(title_backend.read(:en)).to eq("bar")
    end
  end

  context "with cache" do
    before { Article.translates :title, :content, backend: :table, cache: true }
    include_accessor_examples "Article"

    it "only fetches translation once per locale" do
      article = Article.new
      title_backend = backend_for(article, :title)

      aggregate_failures do
        expect(title_backend.model.send(title_backend.association_name)).to receive(:find).twice.and_call_original
        title_backend.write(:en, "foo")
        title_backend.write(:en, "bar")
        expect(title_backend.read(:en)).to eq("bar")
        title_backend.write(:fr, "baz")
        expect(title_backend.read(:fr)).to eq("baz")
      end
    end

    it "resets model translations cache when model is saved or reloaded" do
      article = Article.new
      title_backend = backend_for(article, :title)
      content_backend = backend_for(article, :content)

      aggregate_failures "cacheing reads" do
        title_backend.read(:en)
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(1)
        content_backend.read(:en)
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(1)
        content_backend.read(:ja)
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(2)
      end

      aggregate_failures "resetting cache" do
        article.save
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(0)

        content_backend.read(:ja)
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(1)
        article.reload
        expect(article.instance_variable_get(:@__mobility_translations_cache).size).to eq(0)
      end
    end
  end

  describe "translations association" do
    before { Article.translates :title, :content, backend: :table, cache: true }

    describe "cleaning up blank translations" do
      let(:title_backend) { backend_for(article, :title) }

      it "builds nil translations when reading but does not save them" do
        Mobility.locale = :en
        article = Article.new(title: "New Article")
        association_name = article.mobility_backends[:title].association_name

        Mobility.locale = :ja
        article.title

        Mobility.locale = :fr
        article.title

        aggregate_failures do
          expect(article.send(association_name).size).to eq(3)
          article.save
          expect(article.title).to be_nil
          expect(article.reload.send(association_name).size).to eq(1)
        end
      end

      it "removes nil translations when saving persisted record" do
        Mobility.locale = :en
        article = Article.create(title: "New Article")
        association_name = article.mobility_backends[:title].association_name

        aggregate_failures do
          expect(article.send(association_name).size).to eq(1)

          Mobility.locale = :ja
          article.title = "新規記事"
          expect(article.send(association_name).size).to eq(2)

          article.save
          expect(article.send(association_name).size).to eq(2)

          article.title = nil
          article.save
          article.reload
          expect(article.send(association_name).size).to eq(1)
        end
      end
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
    let(:title_backend) { backend_for(article, :title) }
    let(:content_backend) { backend_for(article, :content) }

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
        }.to change(subject.send(title_backend.association_name), :size).by(1)
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
          }.to change(subject.send(title_backend.association_name), :size).by(1)

          expect { subject.save! }.to change(Article::Translation, :count).by(1)
        end

        it "assigns attributes to translation" do
          title_backend.write(:en, "New Article")
          content_backend.write(:en, "Lorum ipsum...")

          translation = subject.send(title_backend.association_name).first

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
          }.not_to change(subject.send(title_backend.association_name), :size)
        end

        it "updates value attribute on existing translation" do
          title_backend.write(:en, "New New Article")
          subject.save!
          subject.reload

          translation = subject.send(title_backend.association_name).first

          aggregate_failures do
            expect(translation.title).to eq("New New Article")
            expect(translation.translated_model).to eq(subject)
          end
        end
      end
    end
  end

  describe ".configure" do
    let(:options) { { model_class: Article } }
    it "sets association_name" do
      described_class.configure(options)
      expect(options[:association_name]).to eq(:translations)
    end

    it "sets subclass_name" do
      described_class.configure(options)
      expect(options[:subclass_name]).to eq(:Translation)
    end

    it "sets table_name" do
      described_class.configure(options)
      expect(options[:table_name]).to eq(:article_translations)
    end

    it "sets foreign_key" do
      described_class.configure(options)
      expect(options[:foreign_key]).to eq(:article_id)
    end
  end

  describe "mobility scope (.i18n)" do
    before { Article.translates :title, :content, backend: :table, cache: false }
    include_querying_examples('Article')
    include_validation_examples('Article')

    describe "joins" do
      it "uses inner join for WHERE queries if query has at least one non-null attribute" do
        expect(Article.i18n.where(title: "foo", content: nil).to_sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo").where(content: nil).to_sql).not_to match(/OUTER/)
        expect(Article.i18n.where(content: nil).where(title: "foo").to_sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo", content: [nil, "bar"]).to_sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo").where(content: [nil, "bar"]).to_sql).not_to match(/OUTER/)
        expect(Article.i18n.where(content: [nil, "bar"]).where(title: "foo").to_sql).not_to match(/OUTER/)
      end

      it "does not use OUTER JOIN with .not" do
        # we don't need an OUTER join when matching nil values since
        # we're searching for negative matches
        expect(Article.i18n.where.not(title: nil).to_sql).not_to match /OUTER/
      end

      it "works with other joins" do
        article = Article.create(title: "foo")
        expect(Article.i18n.joins(:translations).find_by(title: "foo")).to eq(article)
      end

      describe "Arel queries" do
        before { Article.translates :subtitle, backend: :table }

        describe "uses correct join type" do
          it "works on one attribute with non-null values" do
            aggregate_failures do
              Article.i18n { title.eq("footitle") }.tap do |relation|
                expect(relation.to_sql).to match /INNER/
                expect(relation.to_sql).not_to match /OUTER/
              end
            end
          end

          it "works on one attribute with null values" do
            aggregate_failures do
              Article.i18n { title.eq(nil) }.tap do |relation|
                expect(relation.to_sql).to match /OUTER/
                expect(relation.to_sql).not_to match /INNER/
              end
            end
          end

          it "works on two attributes with non-null values" do
            Article.i18n { title.eq("footitle").or(subtitle.eq("barsubtitle")) }.tap do |relation|
              expect(relation.to_sql).to match /INNER/
              expect(relation.to_sql).not_to match /OUTER/
            end
          end

          it "works on two attributes with null values" do
            aggregate_failures do
              Article.i18n { title.eq(nil).or(title.eq("footitle")) }.tap do |relation|
                expect(relation.to_sql).to match /OUTER/
                expect(relation.to_sql).not_to match /INNER/
              end

              Article.i18n { title.eq(nil).and(subtitle.eq(nil)) }.tap do |relation|
                expect(relation.to_sql).to match /OUTER/
                expect(relation.to_sql).not_to match /INNER/
              end
            end
          end
        end

        # This checks that if we define attributes on the same table with
        # different backend classes, querying will still correctly handle the
        # case where we OR their nodes together and require that *both*
        # predicates have non-nil arguments in order to apply an INNER join. In
        # code, this corresponds to the check that:
        #   +backend_class.table_name == object.backend_class.table_name+
        it "uses outer join when OR-ing nodes on different backends with same table name" do
          article1 = Article.create
          article2 = Article.create(subtitle: "foo")

          expect(Article.i18n { title.eq("foo").or(subtitle.eq(nil)) }.to_sql).to match /OUTER/
          expect(Article.i18n { subtitle.eq(nil).or(title.eq("foo")) }.to_sql).to match /OUTER/
          expect(Article.i18n { title.eq("foo").or(subtitle.eq(nil)) }).to eq([article1])
          expect(Article.i18n { subtitle.eq(nil).or(title.eq("foo")) }).to eq([article1])
        end

        it "combines multiple locales to use correct join type" do
          post1 = Article.new(title: "foo en", subtitle: "bar en")
          Mobility.with_locale(:ja) do
            post1.title = "foo ja"
            post1.subtitle = "bar ja"
          end
          post1.save

          post2 = Article.create(title: "foo en")

          Article.i18n(locale: :en) { |en|
            Article.i18n(locale: :ja) { |ja|
              en.title.eq("foo en").and(ja.title.eq(nil))
            }
          }.tap do |relation|
            expect(relation.to_sql).to match /OUTER/
            expect(relation.to_sql).to match /INNER/
          end
        end
      end
    end

    describe ".order" do
      it "users OUTER JOIN" do
        article1 = Article.create(title: "foo")
        article2 = Article.create

        expect(Article.i18n.order(:title)).to match_array([article1, article2])
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
end if defined?(ActiveRecord)
