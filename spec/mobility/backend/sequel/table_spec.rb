require "spec_helper"

describe "Mobility::Backend::Sequel::Table", orm: :sequel do
  let(:translation_class) { Mobility::Sequel::Translation }
  let(:title_backend) { article.title_translations }
  let(:content_backend) { article.content_translations }

  before do
    stub_const 'Article', Class.new(::Sequel::Model)
    Article.dataset = DB[:articles]
    Article.class_eval do
      include Mobility
      translates :title, :content, backend: :table
    end
  end

  describe "backend methods" do
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
        expect(title_backend.read(:en)).to have_stash("New Article")
        expect(content_backend.read(:en)).to have_stash("Once upon a time...")
        expect(title_backend.read(:ja)).to have_stash("新規記事")
        expect(content_backend.read(:ja)).to have_stash("昔々あるところに…")
      end

      it "returns nil if no translation exists" do
        expect(title_backend.read(:de)).to have_stash(nil)
      end

      describe "reading back written attributes" do
        before do
          title_backend.write(:en, "Changed Article Title")
        end

        it "returns changed value" do
          expect(title_backend.read(:en)).to have_stash("Changed Article Title")
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

          expect(translation.locale).to eq("en")
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New Article")
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

          translation = subject.mobility_translations.first
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New New Article")
          expect(translation.locale).to eq("en")
          expect(translation.translatable).to eq(subject)
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

  describe "creating a new record with translations" do
    it "creates record and translation in current locale" do
      Mobility.locale = :en
      article = Article.create(title: "New Article", content: "Once upon a time...")
      expect(Article.count).to eq(1)
      expect(Mobility::Sequel::Translation.count).to eq(2)
      expect(article.mobility_translations.size).to eq(2)
      expect(article.title).to eq("New Article")
      expect(article.content).to eq("Once upon a time...")
    end

    it "creates translations for other locales" do
      Mobility.locale = :en
      article = Article.create(title: "New Article", content: "Once upon a time...")
      expect(article.mobility_translations.count).to eq(2)
      Mobility.locale = :ja
      expect(article.title).to eq(nil)
      expect(article.content).to eq(nil)
      article.update(title: "新規記事", content: "昔々あるところに…")
      expect(article.title).to eq("新規記事")
      expect(article.content).to eq("昔々あるところに…")
      expect(article.mobility_translations.count).to eq(2)
      article.save
      expect(article.mobility_translations.count).to eq(4)
      expect(Mobility::Sequel::Translation.count).to eq(4)
    end
  end

  describe "storing translations" do
    it "does not save translations unless they have a value present" do
      Mobility.locale = :en
      article = Article.create(title: "New Article")
      Mobility.locale = :ja
      article.title
      article.save
      expect(translation_class.count).to eq(1)
      expect(article.mobility_translations.count).to eq(1)
      article.title = ""
      article.save
      expect(article.title).to be_nil
      expect(translation_class.count).to eq(1)
    end

    it "destroys translation on save if value is set to a blank value" do
      Article.create(title: "New Article")

      article = Article.first
      article.title = ""
      expect { article.valid? }.not_to change(translation_class, :count)
      expect { article.save }.to change(translation_class, :count).by(-1)

      expect(article.title).to eq(nil)
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
      article = Article.create(title: "New Article")
      Mobility.locale = :ja
      article.title = "新規記事"

      article.reload
      article.save
      expect(translation_class.count).to eq(1)
      expect(translation_class.first.value).to eq("New Article")
    end
  end

  describe "Model.first_by_<translated attribute>" do
    it "finds correct translation if exists in current locale" do
      Mobility.locale = :ja
      article = Article.create(title: "タイトル")
      Mobility.locale = :en
      article.title = "Title"
      article.save
      match = Article.first_by_title("Title")
      expect(match).to eq(article)
      Mobility.locale = :ja
      expect(Article.first_by_title("タイトル")).to eq(article)
      expect(Article.first_by_title("foo")).to be_nil
    end

    it "returns nil if no matching translation exists in this locale" do
      Mobility.locale = :ja
      article = Article.create(title: "タイトル")
      Mobility.locale = :en
      expect(Article.first_by_title("タイトル")).to eq(nil)
      expect(Article.first_by_title("foo")).to be_nil
    end
  end
end
