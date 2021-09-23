require "spec_helper"

return unless defined?(::Sequel)

describe "Mobility::Backends::Sequel::Table", orm: :sequel, type: :backend do
  require "mobility/backends/sequel/table"

  before do
    stub_const 'Article', Class.new(Sequel::Model(:articles))
    Article.dataset = DB[:articles]
  end

  let(:title_backend) { article.mobility_backends[:title] }
  let(:content_backend) { article.mobility_backends[:content] }
  let(:article) { Article.new }

  let(:translation_class) { Article::Translation }

  # Note: the cache is required for the Sequel Table backend, so we need to
  # apply it.
  context "with cache plugin only" do
    plugins :cache

    backend_class_with_cache = Class.new(described_class)
    backend_class_with_cache.include_cache

    include_backend_examples backend_class_with_cache, 'Article'
  end

  context "with basic plugins plus cache" do
    plugins :sequel, :reader, :writer, :cache


    before { translates Article, :title, :content, backend: :table }

    include_accessor_examples "Article"
    include_dup_examples "Article"

    it "only fetches translation once per locale" do
      expect(article.send(title_backend.association_name)).to receive(:find).twice.and_call_original
      title_backend.write(:en, "foo")
      title_backend.write(:en, "bar")
      expect(title_backend.read(:en)).to eq("bar")
      title_backend.write(:fr, "baz")
      expect(title_backend.read(:fr)).to eq("baz")
    end
  end

  describe "Backend methods" do
    plugins :sequel, :cache
    before do
      translates Article, :title, :content, backend: :table
      2.times { Article.create }
    end
    let(:article) { Article.last }

    subject { article }

    describe "#read" do
      before do
        [
          { locale: "en", title: "New Article", content: "Once upon a time...", translated_model: article },
          { locale: "ja", title: "新規記事", content: "昔々あるところに…", translated_model: article }
        ].each { |attrs| Article::Translation.create(attrs) }
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
        it "stashes translation" do
          translation = translation_class.new(locale: :en)

          expect(translation_class).to receive(:new).with(locale: :en).and_return(translation)
          expect {
            title_backend.write(:en, "New Article")
          }.not_to change(translation_class, :count)

          aggregate_failures do
            expect(translation.locale).to eq("en")
            expect(translation.title).to eq("New Article")
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
            title: "foo",
            locale: "en",
            translated_model: subject
          )
        end

        it "does not create new translation for locale" do
          expect {
            title_backend.write(:en, "New Article")
            subject.save
          }.not_to change(translation_class, :count)
        end

        it "updates attribute on existing translation" do
          title_backend.write(:en, "New New Article")
          subject.save
          subject.reload

          translation = subject.send(title_backend.association_name).first

          aggregate_failures do
            expect(translation.title).to eq("New New Article")
            expect(translation.locale).to eq("en")
            expect(translation.translated_model).to eq(subject)
          end
        end
      end
    end
  end

  describe ".configure" do
    plugins :sequel

    let(:options) { {} }
    let(:backend_class) do
      described_class.build_subclass(Article, {})
    end

    it "sets association_name" do
      backend_class.configure(options)
      expect(options[:association_name]).to eq(:translations)
    end

    it "sets subclass_name" do
      backend_class.configure(options)
      expect(options[:subclass_name]).to eq(:Translation)
    end

    it "sets table_name" do
      backend_class.configure(options)
      expect(options[:table_name]).to eq(:article_translations)
    end

    it "sets foreign_key" do
      backend_class.configure(options)
      expect(options[:foreign_key]).to eq(:article_id)
    end
  end

  describe "with query (and cache) plugin" do
    plugins :sequel, :reader, :writer, :cache, :query
    before { translates Article, :title, :content, backend: :table }

    include_querying_examples('Article')

    context "with multitable translations" do
      before { translates Article, :foo, backend: :table, table_name: :article_foo_translations, association_name: :foo_translations }

      include_accessor_examples 'Article', :title, :foo
      include_querying_examples 'Article', :title, :foo
    end

    describe "joins" do
      it "uses inner join for WHERE queries if query has at least one non-null attribute" do
        expect(Article.i18n.where(title: "foo", content: nil).sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo").where(content: nil).sql).not_to match(/OUTER/)
        #TODO: get this to pass
        #expect(Article.i18n.where(content: nil).where(title: "foo").sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo", content: [nil, "bar"]).sql).not_to match(/OUTER/)
        expect(Article.i18n.where(title: "foo").where(content: [nil, "bar"]).sql).not_to match(/OUTER/)
        expect(Article.i18n.where(content: [nil, "bar"]).where(title: "foo").sql).not_to match(/OUTER/)
      end
    end
  end

  describe "translation class validations" do
    plugins :sequel, :reader, :writer, :cache
    before { translates Article, :title, backend: :table }

    it "validates presence of locale" do
      article.title = "foo"
      article.save
      translation = article.translations.first
      translation.locale = nil
      expect(translation.valid?).to eq(false)
      expect(translation.errors).to eq(locale: ["is not present"])
    end
  end
end
