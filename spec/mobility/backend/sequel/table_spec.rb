require "spec_helper"

describe "Mobility::Backend::Sequel::Table", orm: :sequel do
  let(:translation_class) { Mobility::Sequel::TextTranslation }
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
      expect(Mobility::Sequel::TextTranslation.count).to eq(2)
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
      expect(Mobility::Sequel::TextTranslation.count).to eq(4)
    end
  end

  context "with separate string and text translations" do
    before do
      Article.class_eval do
        translates :short_title, backend: :table, class_name: Mobility::Sequel::StringTranslation, association_name: :mobility_string_translations
      end
    end

    it "saves translations correctly" do
      article = Article.create(title: "foo title", short_title: "bar short title")
      expect(article.title).to eq("foo title")
      expect(article.short_title).to eq("bar short title")

      article = Article.first
      expect(article.title).to eq("foo title")
      expect(article.short_title).to eq("bar short title")

      text = Mobility::Sequel::TextTranslation.first
      expect(text.value).to eq("foo title")

      string = Mobility::Sequel::StringTranslation.first
      expect(string.value).to eq("bar short title")
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

  describe "mobility dataset (.i18n)" do
    describe ".where" do
      context "querying on one translated attribute" do
        before do
          @post1 = Post.create(title: "foo post")
          @post2 = Post.create(title: "bar post")
          @post3 = Post.create(title: "baz post", published: true)
          @post4 = Post.create(title: "baz post", published: false)
          @post5 = Post.create(title: "foo post", published: true)
        end

        it "returns correct result searching on unique attribute value" do
          expect(Post.i18n.where(title: "bar post").select_all(:posts).all).to eq([@post2])
        end

        it "returns correct results when query matches multiple records" do
          expect(Post.i18n.where(title: "foo post").select_all(:posts).all).to match_array([@post1, @post5])
        end

        it "returns correct result when querying on translated and untranslated attributes" do
          expect(Post.i18n.where(title: "baz post", published: true).select_all(:posts).all).to eq([@post3])
        end

        it "returns correct result when querying on nil values" do
          post = Post.create(title: nil)
          expect(Post.i18n.where(title: nil).select_all(:posts).all).to eq([post])
        end

        it "uses inner join" do
          expect(Post.i18n.where(title: "foo").sql).not_to match(/OUTER/)
        end

        context "with content in different locales" do
          before do
            Mobility.with_locale(:ja) do
              @ja_post1 = Post.create(title: "foo post ja")
              @ja_post2 = Post.create(title: "foo post")
            end
          end

          it "returns correct result when querying on same attribute value in different locale" do
            expect(Post.i18n.where(title: "foo post").select_all(:posts).all).to match_array([@post1, @post5])

            Mobility.with_locale(:ja) do
              expect(Post.i18n.where(title: "foo post ja").select_all(:posts).all).to eq([@ja_post1])
              expect(Post.i18n.where(title: "foo post").select_all(:posts).all).to eq([@ja_post2])
            end
          end

          #TODO: This would be nice, but will be complicated to implement.
          pending "returns correct result using locale accessors in query" do
            expect(Post.i18n.where(title_ja: "foo post ja").select_all(:posts).all).to eq(@ja_post1)
            expect(Post.i18n.where(title_en: "foo post").select_all(:posts).all).to match_array([@post1, @post5])
          end
        end
      end

      context "model with two translated attributes on same table" do
        before do
          @post1 = Post.create(title: "foo post"                                          )
          @post2 = Post.create(title: "foo post", content: "foo content"                  )
          @post3 = Post.create(title: "foo post", content: "foo content", published: false)
          @post4 = Post.create(                   content: "foo content"                  )
          @post5 = Post.create(title: "bar post", content: "bar content"                  )
          @post6 = Post.create(title: "bar post",                         published: true )
        end

        it "returns correct results querying on one attribute" do
          expect(Post.i18n.where(title: "foo post").select_all(:posts).all).to match_array([@post1, @post2, @post3])
          expect(Post.i18n.where(content: "foo content").select_all(:posts).all).to match_array([@post2, @post3, @post4])
        end

        it "returns correct results querying on two attributes in single where call" do
          expect(Post.i18n.where(title: "foo post", content: "foo content").select_all(:posts).all).to match_array([@post2, @post3])
        end

        it "returns correct results querying on two attributes in separate where calls" do
          expect(Post.i18n.where(title: "foo post").where(content: "foo content").select_all(:posts).all).to match_array([@post2, @post3])
        end

        it "returns correct result querying on two translated attributes and untranslated attribute" do
          expect(Post.i18n.where(title: "foo post", content: "foo content", published: false).select_all(:posts).all).to eq([@post3])
        end

        it "works with nil values" do
          expect(Post.i18n.where(title: "foo post", content: nil).select_all(:posts).all).to eq([@post1])
          post = Post.create
          expect(Post.i18n.where(title: nil, content: nil).select_all(:posts).all).to eq([post])
        end

        pending "returns correct result searching with string using select" do
          expect(Post.i18n.select(:title, :content, "posts.*").where("title = 'foo post' AND content = 'foo content'").select_all(:posts).all).to match_array([@post2, @post3])
        end

        context "with content in different locales" do
          before do
            Mobility.with_locale(:ja) do
              @ja_post1 = Post.create(title: "foo post ja", content: "foo content ja")
              @ja_post2 = Post.create(title: "foo post",    content: "foo content"   )
              @ja_post3 = Post.create(title: "foo post"                              )
            end
          end

          it "returns correct result when querying on same attribute values in different locale" do
            expect(Post.i18n.where(title: "foo post", content: "foo content").select_all(:posts).all).to match_array([@post2, @post3])

            Mobility.with_locale(:ja) do
              expect(Post.i18n.where(title: "foo post").select_all(:posts).all).to eq([@ja_post2, @ja_post3])
              expect(Post.i18n.where(title: "foo post", content: "foo content").select_all(:posts).all).to eq([@ja_post2])
              expect(Post.i18n.where(title: "foo post ja", content: "foo content ja").select_all(:posts).all).to eq([@ja_post1])
            end
          end
        end
      end

      context "model with two translated attributes on different tables" do
        before do
          Article.class_eval do
            translates :short_title, backend: :table, class_name: Mobility::Sequel::StringTranslation, association_name: :mobility_string_translations
          end
          @article1 = Article.create(title: "foo post", short_title: "bar short 1")
          @article2 = Article.create(title: "foo post", short_title: "bar short 2")
          @article3 = Article.create(                   short_title: "bar short 1")
        end

        it "returns correct result when querying on multiple tables" do
          expect(Article.i18n.where(title: "foo post", short_title: "bar short 2").select_all(:articles).all).to eq([@article2])
          expect(Article.i18n.where(title: nil, short_title: "bar short 2").select_all(:articles).all).to eq([])
          expect(Article.i18n.where(title: nil, short_title: "bar short 1").select_all(:articles).all).to eq([@article3])
        end
      end
    end

    describe ".invert" do
      before do
        @post1 = Post.create(title: "foo post"                                          )
        @post2 = Post.create(title: "foo post", content: "foo content"                  )
        @post3 = Post.create(title: "foo post", content: "foo content", published: false)
        @post4 = Post.create(                   content: "foo content"                  )
        @post5 = Post.create(title: "bar post", content: "bar content", published: true )
        @post6 = Post.create(title: "bar post", content: "bar content", published: false)
        @post7 = Post.create(                                           published: true)
      end

      it "returns record without translated attribute value" do
        expect(Post.i18n.where(title: "foo post").invert.select_all(:posts).all).to match_array([@post5, @post6])
      end

      it "works in combination with untranslated attributes" do
        expect(Post.i18n.where(title: "foo post", published: true).invert.select_all(:posts).all).to eq([@post1, @post2, @post3, @post5, @post6])
        expect(Post.i18n.where(title: "foo post").or(published: true).invert.select_all(:posts).all).to eq([@post6])
      end

      it "works with nil values" do
        expect(Post.i18n.where(title: nil).invert.select_all(:posts).all).to match_array([@post1, @post2, @post3, @post5, @post6])

        # we don't need an OUTER join when matching nil values since we're searching for negative matches
        expect(Post.i18n.where(title: nil).invert.sql).not_to match /OUTER/

        # but we should not remove other OUTER joins
        expect(Post.i18n.where(title: nil).join_table(:left_outer, :post_metadatas).invert.sql).to match /LEFT OUTER JOIN \`post_metadatas/
      end
    end

    describe "Model.i18n.first_by_<translated attribute>" do
      it "finds correct translation if exists in current locale" do
        Mobility.locale = :ja
        article = Article.create(title: "タイトル")
        Mobility.locale = :en
        article.title = "Title"
        article.save
        match = Article.i18n.first_by_title("Title")
        expect(match).to eq(article)
        Mobility.locale = :ja
        expect(Article.i18n.first_by_title("タイトル")).to eq(article)
        expect(Article.i18n.first_by_title("foo")).to be_nil
      end

      it "returns nil if no matching translation exists in this locale" do
        Mobility.locale = :ja
        article = Article.create(title: "タイトル")
        Mobility.locale = :en
        expect(Article.i18n.first_by_title("タイトル")).to eq(nil)
        expect(Article.i18n.first_by_title("foo")).to be_nil
      end
    end
  end
end
