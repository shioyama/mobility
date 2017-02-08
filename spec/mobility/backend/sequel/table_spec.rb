require "spec_helper"

describe "Mobility::Backend::Sequel::Table", orm: :sequel do
  extend Helpers::Sequel

  let(:described_class) { Mobility::Backend::Sequel::KeyValue }
  let(:translation_class) { Article::Translation }

  before do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article.include Mobility
    Article.translates :title, :content, backend: :table, cache: true
  end

  include_accessor_examples "Article"

  # Using Article to test separate backends with separate tables fails
  # when these specs are run together with other specs, due to code
  # assigning subclasses (Article::Translation, Article::FooTranslation).
  # Maybe an issue with RSpec const stubbing.
  context "attributes defined separately" do
    include_accessor_examples "MultitablePost", :title, :foo
    include_querying_examples "MultitablePost", :title, :foo
  end

  describe "Backend methods" do
    before { %w[foo bar baz].each { |slug| Article.create(slug: slug) } }
    let(:article) { Article.find(slug: "baz") }
    let(:title_backend) { article.title_translations }
    let(:content_backend) { article.content_translations }

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

          translation = subject.mobility_model_translations.first

          aggregate_failures do
            expect(translation.title).to eq("New New Article")
            expect(translation.locale).to eq("en")
            expect(translation.translated_model).to eq(subject)
          end
        end
      end
    end
  end

  describe "mobility scope (.i18n)" do
    before { Article.translates :title, :content, backend: :table, cache: true }
    include_querying_examples('Article')
  end
end
