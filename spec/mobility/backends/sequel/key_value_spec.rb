require "spec_helper"

describe "Mobility::Backends::Sequel::KeyValue", orm: :sequel do
  require "mobility/backends/sequel/key_value"
  extend Helpers::Sequel

  # Note: the cache is required for the Sequel Table backend, so we need to
  # apply it.
  context "with only cache plugins applied" do
    before do
      stub_const 'Article', Class.new(Sequel::Model(:articles))
      Article.extend Mobility
    end
    backend_class_with_cache = Class.new(described_class)
    backend_class_with_cache.apply_plugin(:cache)

    include_backend_examples backend_class_with_cache, 'Article', type: :text
  end

  context "with standard plugins applied" do
    let(:described_class) { Mobility::Backends::Sequel::KeyValue }
    let(:translation_class) { Mobility::Sequel::TextTranslation }
    let(:title_backend) { article.mobility_backends[:title] }
    let(:content_backend) { article.mobility_backends[:content] }

    before do
      stub_const 'Article', Class.new(::Sequel::Model)
      Article.dataset = DB[:articles]
      Article.class_eval do
        extend Mobility
        translates :title, :content, backend: :key_value, type: :text
        translates :subtitle, backend: :key_value, type: :text
      end
    end

    include_accessor_examples 'Article'
    include_dup_examples 'Article'

    describe "cache" do
      let(:article) { Article.new }

      it "only fetches translation once per locale" do
        expect(article.send(title_backend.association_name)).to receive(:find).twice.and_call_original
        title_backend.write(:en, "foo")
        title_backend.write(:en, "bar")
        expect(title_backend.read(:en)).to eq("bar")
        title_backend.write(:fr, "baz")
        expect(title_backend.read(:fr)).to eq("baz")
      end

      it "resets translations cache when model is refreshed" do
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
          article.refresh
          expect(title_backend.send(:cache).size).to eq(0)
          expect(content_backend.send(:cache).size).to eq(0)
        end
      end
    end

    describe "Backend methods" do
      before { %w[foo bar baz].each { |slug| Article.create(slug: slug) } }
      let(:article) { Article.find(slug: "baz") }

      subject { article }

      describe "#read" do
        before do
          [
            { key: "title", value: "New Article", locale: "en", translatable: article },
            { key: "title", value: "新規記事", locale: "ja", translatable: article },
            { key: "content", value: "Once upon a time...", locale: "en", translatable: article },
            { key: "content", value: "昔々あるところに…", locale: "ja", translatable: article }
          ].each { |attrs| translation_class.create(attrs) }
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
          it "stashes translation with value" do
            translation = translation_class.new(locale: :en, key: "title")

            expect(translation_class).to receive(:new).with(locale: :en, key: "title").and_return(translation)
            expect {
              title_backend.write(:en, "New Article")
            }.not_to change(translation_class, :count)

            aggregate_failures do
              expect(translation.locale).to eq("en")
              expect(translation.key).to eq("title")
              expect(translation.value).to eq("New Article")
            end
          end

          it "creates translation for locale when model is saved" do
            title_backend.write(:en, "New Article")
            expect { subject.save }.to change(translation_class, :count).by(1)
          end
        end

        context "translation for locale exists" do
          before do
            translation_class.create(
              key: "title",
              value: "foo",
              locale: "en",
              translatable: subject
            )
          end

          it "does not create new translation for locale" do
            expect {
              title_backend.write(:en, "New Article")
              subject.save
            }.not_to change(translation_class, :count)
          end

          it "updates value attribute on existing translation" do
            title_backend.write(:en, "New New Article")
            subject.save
            subject.reload

            translation = subject.send(title_backend.association_name).first

            aggregate_failures do
              expect(translation.key).to eq("title")
              expect(translation.value).to eq("New New Article")
              expect(translation.locale).to eq("en")
              expect(translation.translatable).to eq(subject)
            end
          end

          it "removes translation if assigned nil when record is saved" do
            expect {
              title_backend.write(:en, nil)
            }.not_to change(translation_class, :count)

            expect {
              subject.save
            }.to change(translation_class, :count).by(-1)
          end
        end
      end
    end

    describe "translations association" do
      let(:article) { Article.create(title: "Article", subtitle: "Article subtitle", content: "Content") }

      it "limits association to translations with keys matching attributes" do
        translation = Mobility::Sequel::TextTranslation.create(key: "foo", value: "bar", locale: "en", translatable: article)
        article = Article.first

        aggregate_failures do
          expect(article.send(title_backend.association_name)).not_to include(translation)
          expect(article.send(title_backend.association_name).count).to eq(3)
        end
      end
    end

    describe "creating a new record with translations" do
      let!(:article) { Article.create(title: "New Article", content: "Once upon a time...") }

      it "creates record and translation in current locale" do
        Mobility.locale = :en

        aggregate_failures do
          expect(Article.count).to eq(1)
          expect(Mobility::Sequel::TextTranslation.count).to eq(2)
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

        aggregate_failures "in other locale" do
          Mobility.locale = :ja
          expect(article.title).to eq(nil)
          expect(article.content).to eq(nil)
          article.update(title: "新規記事", content: "昔々あるところに…")
          expect(article.title).to eq("新規記事")
          expect(article.content).to eq("昔々あるところに…")
          expect(article.send(title_backend.association_name).count).to eq(4)
        end

        aggregate_failures "after reloading" do
          article = Article.first
          expect(article.send(title_backend.association_name).count).to eq(4)
          expect(Mobility::Sequel::TextTranslation.count).to eq(4)
        end
      end
    end

    context "with separate string and text translations" do
      before do
        Article.class_eval do
          translates :short_title, backend: :key_value, class_name: Mobility::Sequel::StringTranslation, association_name: :string_translations
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

          text = Mobility::Sequel::TextTranslation.first
          expect(text.value).to eq("foo title")

          string = Mobility::Sequel::StringTranslation.first
          expect(string.value).to eq("bar short title")
        end
      end
    end

    describe "storing translations" do
      let!(:article) do
        Mobility.with_locale(:en) { article = Article.create(title: "New Article") }
      end

      it "does not save translations unless they have a value present" do
        aggregate_failures do
          Mobility.locale = :ja
          article.title
          article.save
          expect(translation_class.count).to eq(1)
          expect(article.send(title_backend.association_name).count).to eq(1)
          article.title = ""
          article.save
          expect(article.title).to be_nil
          expect(translation_class.count).to eq(1)
        end
      end

      it "destroys translation on save if value is set to a blank value" do
        article.title = ""

        aggregate_failures do
          expect { article.valid? }.not_to change(translation_class, :count)
          expect { article.save }.to change(translation_class, :count).by(-1)

          expect(article.title).to eq(nil)
        end
      end

      it "does not override after_save method" do
        mod = Module.new do
          attr_reader :after_save_called
          def after_save
            super
            @after_save_called = true
          end
        end
        Article.prepend(mod)

        Mobility.locale = :en
        article = Article.create(title: "New Article")
        article.save
        expect(article.after_save_called).to eq(true)
      end

      it "resets translations if model is reloaded" do
        Mobility.locale = :ja
        article.title = "新規記事"

        article.reload
        article.save

        aggregate_failures do
          expect(translation_class.count).to eq(1)
          expect(translation_class.first.value).to eq("New Article")
        end
      end
    end

    describe "after destroy" do
      # In case we change the translated attributes on a model, we need to make
      # sure we clean them up when the model is destroyed.
      it "cleans up all associated translations, regardless of key" do
        article = Article.create(title: "foo title", content: "foo content")
        Mobility.with_locale(:ja) { article.update(title: "あああ", content: "ばばば") }
        article.save

        # Create translations on another model, to check they do not get destroyed
        Post.create(title: "post title", content: "post content")

        expect(Mobility::Sequel::StringTranslation.count).to eq(1)
        expect(Mobility::Sequel::TextTranslation.count).to eq(5)

        Mobility::Sequel::TextTranslation.create(translatable: article, key: "key1", value: "value1", locale: "de")
        Mobility::Sequel::StringTranslation.create(translatable: article, key: "key2", value: "value2", locale: "fr")
        expect(Mobility::Sequel::TextTranslation.count).to eq(6)
        expect(Mobility::Sequel::StringTranslation.count).to eq(2)

        article.destroy
        expect(Mobility::Sequel::TextTranslation.count).to eq(1)
        expect(Mobility::Sequel::StringTranslation.count).to eq(1)
      end

      it "only destroys translations once when cleaning up" do
        article = Article.create(title: "foo title", content: "foo content")
        # This is an ugly way to check that we are not destroying all
        # translations twice. Since the actual callback is included in a module,
        # it's hard to get at this directly.
        expect(Mobility::Sequel::TextTranslation).to receive(:where).once.and_call_original
        expect(Mobility::Sequel::StringTranslation).to receive(:where).once.and_call_original
        article.destroy
      end
    end

    describe ".configure" do
      it "sets association_name, class_name and table_alias_affix from string type" do
        options = { type: :string, model_class: Post }
        described_class.configure(options)
        expect(options).to eq({
          type: :string,
          class_name: Mobility::Sequel::StringTranslation,
          model_class: Post,
          association_name: :string_translations,
          table_alias_affix: "Post_%s_string_translations"
        })
      end

      it "sets association_name, class_name and table_alias_affix from text type" do
        options = { type: :text, model_class: Post }
        described_class.configure(options)
        expect(options).to eq({
          type: :text,
          class_name: Mobility::Sequel::TextTranslation,
          model_class: Post,
          association_name: :text_translations,
          table_alias_affix: "Post_%s_text_translations"
        })
      end

      it "raises ArgumentError if type has no corresponding model class" do
        expect { described_class.configure(type: "integer") }
          .to raise_error(ArgumentError,
                          "You must define a Mobility::Sequel::IntegerTranslation class.")
      end


      it "sets default association_name, class_name and table_alias_affix from type" do
        options = { type: :text, model_class: Post }
        described_class.configure(options)
        expect(options).to eq({
          type: :text,
          class_name: Mobility::Sequel::TextTranslation,
          model_class: Post,
          association_name: :text_translations,
          table_alias_affix: "Post_%s_text_translations"
        })
      end
    end

    describe "mobility dataset (.i18n)" do
      include_querying_examples 'Post'

      describe "joins" do
        it "uses inner join for WHERE queries with non-nil values" do
          expect(Post.i18n.where(title: "foo").sql).not_to match(/OUTER/)
        end
      end

      context "model with two translated attributes on different tables" do
        before do
          Article.class_eval do
            translates :short_title, backend: :key_value, class_name: Mobility::Sequel::StringTranslation, association_name: :string_translations
          end
          @article1 = Article.create(title: "foo post", short_title: "bar short 1")
          @article2 = Article.create(title: "foo post", short_title: "bar short 2")
          @article3 = Article.create(                   short_title: "bar short 1")
        end

        it "returns correct result when querying on multiple tables" do
          aggregate_failures do
            expect(Article.i18n.where(title: "foo post", short_title: "bar short 2").select_all(:articles).all).to eq([@article2])
            expect(Article.i18n.where(title: nil, short_title: "bar short 2").select_all(:articles).all).to eq([])
            expect(Article.i18n.where(title: nil, short_title: "bar short 1").select_all(:articles).all).to eq([@article3])
          end
        end
      end
    end
  end
end if defined?(Sequel)
