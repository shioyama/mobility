require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::KeyValue", orm: :active_record, type: :backend do
  require "mobility/backends/active_record/key_value"

  before { stub_const 'Article', Class.new(ActiveRecord::Base) }

  let(:title_backend)   { backend_for(article, :title) }
  let(:content_backend) { backend_for(article, :content) }
  let(:article) { Article.new }

  let(:string_translation_class) { Mobility::Backends::ActiveRecord::KeyValue::StringTranslation }
  let(:text_translation_class) { Mobility::Backends::ActiveRecord::KeyValue::TextTranslation }

  context "with no plugins" do
    include_backend_examples described_class, 'Article', type: :text
  end

  context "with basic plugins" do
    plugins :active_record, :reader, :writer

    context "without cache" do
      before { translates Article, :title, :content, backend: :key_value, type: :text }

      include_accessor_examples "Article"
      include_dup_examples "Article"
      include_cache_key_examples "Article"

      it "finds translation on every read/write" do
        expect(title_backend.send(:translations)).to receive(:find).thrice.and_call_original
        title_backend.write(:en, "foo")
        title_backend.write(:en, "bar")
        expect(title_backend.read(:en)).to eq("bar")
      end
    end

    context "with cache" do
      plugins :active_record, :reader, :writer, :cache
      before { translates Article, :title, :content, backend: :key_value, type: :text }

      include_accessor_examples "Article"

      it "only fetches translation once per locale" do
        expect(title_backend.send(:translations)).to receive(:find).twice.and_call_original
        title_backend.write(:en, "foo")
        title_backend.write(:en, "bar")
        expect(title_backend.read(:en)).to eq("bar")
        title_backend.write(:fr, "baz")
        expect(title_backend.read(:fr)).to eq("baz")
      end

      it "resets translations cache when model is saved or reloaded" do
        aggregate_failures "cacheing reads" do
          title_backend.read(:en)
          expect(title_backend.send(:cache).size).to eq(1)
          expect(content_backend.send(:cache).size).to eq(0)
          title_backend.read(:ja)
          expect(title_backend.send(:cache).size).to eq(2)
          expect(content_backend.send(:cache).size).to eq(0)
          content_backend.read(:fr)
          expect(title_backend.send(:cache).size).to eq(2)
          expect(content_backend.send(:cache).size).to eq(1)
        end

        aggregate_failures "resetting cache" do
          article.save
          expect(title_backend.send(:cache).size).to eq(0)
          expect(content_backend.send(:cache).size).to eq(0)

          content_backend.read(:ja)
          expect(title_backend.send(:cache).size).to eq(0)
          expect(content_backend.send(:cache).size).to eq(1)
          article.reload
          expect(title_backend.send(:cache).size).to eq(0)
          expect(content_backend.send(:cache).size).to eq(0)
        end
      end
    end

    describe "Backend methods" do
      plugins :active_record
      before do
        translates Article, :title, :content, backend: :key_value, type: :text
        2.times { Article.create! }
      end
      let(:article) { Article.last }

      subject { article }

      describe "#read" do
        before do
          [
            { key: "title", value: "New Article", locale: "en", translatable: article },
            { key: "title", value: "新規記事", locale: "ja", translatable: article },
            { key: "content", value: "Once upon a time...", locale: "en", translatable: article },
            { key: "content", value: "昔々あるところに…", locale: "ja", translatable: article }
          ].each { |attrs| text_translation_class.create!(attrs) }
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

            expect { subject.save! }.to change(text_translation_class, :count).by(1)
          end

          it "assigns attributes to translation" do
            title_backend.write(:en, "New Article")

            translation = subject.send(title_backend.association_name).first

            aggregate_failures do
              expect(translation.key).to eq("title")
              expect(translation.value).to eq("New Article")
              expect(translation.translatable).to eq(subject)
            end
          end
        end

        context "translation for locale exists" do
          before do
            text_translation_class.create!(
              key: "title",
              value: "foo",
              locale: "en",
              translatable: subject
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
              expect(translation.key).to eq("title")
              expect(translation.value).to eq("New New Article")
              expect(translation.translatable).to eq(subject)
            end
          end

          it "removes persisted translation if assigned nil when record is saved" do
            expect(text_translation_class.count).to eq(1)
            expect {
              title_backend.write(:en, nil)
            }.not_to change(subject.send(title_backend.association_name), :count)

            expect {
              subject.save!
            }.to change(subject.send(title_backend.association_name), :count).by(-1)

            expect(text_translation_class.count).to eq(0)
          end

          it "removes unpersisted translation if value is nil when record is saved" do
            article = Article.first
            backend = article.mobility_backends[:title]
            expect(backend.read(:en)).to eq(nil)
            backend.write(:en, "")
            expect(article.send(backend.association_name).size).to eq(1)
            article.save
            expect(article.send(backend.association_name).size).to eq(0)
          end
        end
      end
    end

    describe "translations association" do
      plugins :active_record, :writer

      before do
        translates Article, :title, :content, :subtitle, backend: :key_value, type: :text
        Article.create(title: "Article", subtitle: "Article subtitle", content: "Content")
      end

      it "limits association to translations with keys matching attributes" do
        # This limits the results returned by the association to only those whose keys match the set of
        # translated attributes we have defined. This matters if, say, we save some translations, then change
        # the translated attributes for the model; we should only see the new translations, not the ones
        # created earlier with different keys.
        translation = text_translation_class.create(key: "foo", value: "bar", locale: "en", translatable: article)
        article = Article.first

        aggregate_failures do
          expect(article.send(title_backend.association_name)).not_to include(translation)
          expect(article.send(title_backend.association_name).count).to eq(3)
        end
      end
    end

    describe "creating a new record with translations" do
      plugins :active_record, :reader, :writer

      before { translates Article, :title, :content, backend: :key_value, type: :text }
      let!(:article) { Article.create(title: "New Article", content: "Once upon a time...") }

      it "creates record and translation in current locale" do
        Mobility.locale = :en

        aggregate_failures do
          expect(Article.count).to eq(1)
          expect(text_translation_class.count).to eq(2)
          expect(article.send(title_backend.association_name).size).to eq(2)
          expect(article.title).to eq("New Article")
          expect(article.content).to eq("Once upon a time...")
        end
      end

      it "creates translations for other locales" do
        Mobility.locale = :en

        aggregate_failures "in one locale" do
          expect(article.send(title_backend.association_name).count).to eq(2)
        end

        aggregate_failures "in another locale" do
          Mobility.locale = :ja
          expect(article.title).to eq(nil)
          expect(article.content).to eq(nil)
          article.update!(title: "新規記事", content: "昔々あるところに…")
          expect(article.title).to eq("新規記事")
          expect(article.content).to eq("昔々あるところに…")
          expect(Article.count).to eq(1)
          expect(text_translation_class.count).to eq(4)
          expect(article.send(title_backend.association_name).size).to eq(4)
        end
      end

      it "builds nil translations when reading but does not save them" do
        Mobility.locale = :en
        article = Article.create(title: "New Article")
        Mobility.locale = :ja
        article.title

        aggregate_failures do
          expect(article.send(title_backend.association_name).size).to eq(2)
          article.save
          expect(article.title).to be_nil
          expect(article.reload.send(title_backend.association_name).size).to eq(1)
        end
      end
    end

    context "with separate string and text translations" do
      plugins :active_record, :reader, :writer
      before do
        translates Article, :title, backend: :key_value, type: :text
        translates Article, :short_title, backend: :key_value, class_name: string_translation_class, association_name: :string_translations
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

          text = text_translation_class.first
          expect(text.value).to eq("foo title")

          string = string_translation_class.first
          expect(string.value).to eq("bar short title")
        end
      end
    end

    describe "after destroy" do
      plugins :active_record, :reader, :writer
      before do
        translates Article, :title, :content, backend: :key_value, type: :text
        stub_const 'Post', Class.new(ActiveRecord::Base)
        translates Post, :title, backend: :key_value, type: :string
        translates Post, :content, backend: :key_value, type: :text
      end

      # In case we change the translated attributes on a model, we need to make
      # sure we clean them up when the model is destroyed.
      it "cleans up all associated translations, regardless of key" do
        article = Article.create(title: "foo title", content: "foo content")
        Mobility.with_locale(:ja) { article.update(title: "あああ", content: "ばばば") }
        article.save

        # Create translations on another model, to check they do not get destroyed
        Post.create(title: "post title", content: "post content")

        expect(string_translation_class.count).to eq(1)
        expect(text_translation_class.count).to eq(5)

        text_translation_class.create!(translatable: article, key: "key1", value: "value1", locale: "de")
        string_translation_class.create!(translatable: article, key: "key2", value: "value2", locale: "fr")
        expect(text_translation_class.count).to eq(6)
        expect(string_translation_class.count).to eq(2)

        article.destroy!
        expect(text_translation_class.count).to eq(1)
        expect(string_translation_class.count).to eq(1)
      end
    end

    describe ".configure" do
      plugins :active_record

      before { translates Article, :title, :content, backend: :key_value, type: :text }

      let(:backend_class) do
        Class.new(described_class) { @model_class = Article }
      end

      it "sets association_name and class_name from string type" do
        options = { type: :string }
        backend_class.configure(options)
        expect(options).to eq({
          type: :string,
          class_name: string_translation_class,
          association_name: :string_translations
        })
      end

      it "sets association_name and class_name from text type" do
        options = { type: :text }
        backend_class.configure(options)
        expect(options).to eq({
          type: :text,
          class_name: text_translation_class,
          association_name: :text_translations
        })
      end

      it "raises ArgumentError if type has no corresponding model class" do
        expect { backend_class.configure(type: "integer") }
          .to raise_error(ArgumentError,
                          "You must define a Mobility::Backends::ActiveRecord::KeyValue::IntegerTranslation class.")
      end

      it "sets default association_name and class_name from type" do
        options = { type: :text }
        backend_class.configure(options)
        expect(options).to eq({
          type: :text,
          class_name: text_translation_class,
          association_name: :text_translations
        })
      end
    end

    describe "mobility scope (.i18n)" do
      plugins :active_record, :reader, :writer, :query

      before do
        translates Article, :title, :content, backend: :key_value, type: :text
        translates Article, :subtitle, backend: :key_value, type: :text
      end

      include_querying_examples('Article')
      include_validation_examples('Article')

      describe "joins" do
        it "uses inner join for WHERE queries" do
          expect(Article.i18n.where(title: "foo").to_sql).not_to match(/OUTER/)
        end

        it "does not use OUTER JOIN with .not" do
          # we don't need an OUTER join when matching nil values since
          # we're searching for negative matches
          expect(Article.i18n.where.not(title: nil).to_sql).not_to match /OUTER/
        end

        describe "Arel queries" do
          it "works on one attribute with non-null values" do
            aggregate_failures do
              Article.i18n { content.eq("bazcontent") }.tap do |relation|
                expect(relation.to_sql).to match /INNER/
                expect(relation.to_sql).not_to match /OUTER/
              end
            end
          end

          it "works on one attribute with null values" do
            aggregate_failures do
              Article.i18n { content.eq(nil) }.tap do |relation|
                expect(relation.to_sql).to match /OUTER/
                expect(relation.to_sql).not_to match /INNER/
              end
            end
          end

          # KeyValue must always OUTER JOIN on an OR combinator, otherwised
          # predicate will be false even if one clause is true.
          it "works on two attributes with non-null values" do
            aggregate_failures do
              Article.i18n { content.eq("bazcontent").or(subtitle.eq("foosubtitle")) }.tap do |relation|
                expect(relation.to_sql).to match /OUTER/
                expect(relation.to_sql).not_to match /INNER/
              end
            end
          end
        end
      end

      context "model with two translated attributes on different tables" do
        before do
          translates Article, :short_title, backend: :key_value, class_name: string_translation_class, association_name: :string_translations
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

      describe ".order" do
        it "users OUTER JOIN" do
          article1 = Article.create(title: "foo")
          article2 = Article.create

          expect(Article.i18n.order(:title)).to match_array([article1, article2])
        end
      end
    end

    describe "Model.find_by_<translated attribute>" do
      plugins :active_record, :reader, :writer, :query
      before { translates Article, :title, backend: :key_value, type: :text }

      it "finds correct translation if exists in current locale" do
        Mobility.locale = :ja
        article = Article.create(title: "タイトル")
        expect(Article.find_by_title("タイトル")).to eq(article)
        expect(Article.find_by_title("foo")).to be_nil
      end

      it "returns nil if no matching translation exists in this locale" do
        Mobility.locale = :ja
        article = Article.create(title: "タイトル")
        Mobility.locale = :en
        expect(Article.find_by_title("タイトル")).to eq(nil)
        expect(Article.find_by_title("foo")).to be_nil
      end

      it "works on a scope" do
        Mobility.locale = :ja
        article1 = Article.create(title: "タイトル")
        Mobility.locale = :en
        article2 = Article.create(title: "title")
        Mobility.with_locale(:ja) do
          expect(Article.all.find_by_title("タイトル")).to eq(article1)
        end
      end
    end
  end
end
