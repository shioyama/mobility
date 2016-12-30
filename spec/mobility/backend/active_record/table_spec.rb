require "spec_helper"

describe Mobility::Backend::ActiveRecord::Table, orm: :active_record do
  context "in isolation" do
    let(:attributes) { ["title", "content"] }
    let(:options) { {} }
    let(:title_backend) { article.title_translations }
    let(:content_backend) { article.content_translations }
    let(:article) { Article.find_by(slug: "baz") }

    subject { article }

    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.include Mobility
      Article.translates *attributes, backend: :table, cache: false

      # create some articles
      %w[foo bar baz].each { |slug| Article.create!(slug: slug) }
    end

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
        expect(title_backend.read(:en)).to have_stash("New Article")
        expect(content_backend.read(:en)).to have_stash("Once upon a time...")
        expect(title_backend.read(:ja)).to have_stash("新規記事")
        expect(content_backend.read(:ja)).to have_stash("昔々あるところに…")
      end

      it "returns nil if no translation exists" do
        expect(title_backend.read(:de)).to have_stash(nil)
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
          expect(title_backend.read(:en)).to have_stash("Changed Article Title")
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
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New Article")
          expect(translation.translatable).to eq(subject)
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
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New New Article")
          expect(translation.translatable).to eq(subject)
        end

        it "removes translation if assigned nil when record is saved" do
          expect {
            title_backend.write(:en, nil)
          }.not_to change(subject.send(:mobility_text_translations), :count)

          expect {
            subject.save!
          }.to change(subject.send(:mobility_text_translations), :count).by(-1)
        end
      end
    end
  end

  context "included in AR model" do
    before do
      stub_const('Article', Class.new(ActiveRecord::Base)).class_eval do
        include Mobility
        translates :title, :content, backend: :table
      end
    end

    describe "creating a new record with translations" do
      it "creates record and translation in current locale" do
        Mobility.locale = :en
        article = Article.create(title: "New Article", content: "Once upon a time...")
        expect(Article.count).to eq(1)
        expect(Mobility::ActiveRecord::TextTranslation.count).to eq(2)
        expect(article.send(:mobility_text_translations).size).to eq(2)
        expect(article.title).to eq("New Article")
        expect(article.content).to eq("Once upon a time...")
      end

      it "creates translations for other locales" do
        Mobility.locale = :en
        article = Article.create(title: "New Article", content: "Once upon a time...")
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

      it "builds nil translations when reading but does not save them" do
        Mobility.locale = :en
        article = Article.create(title: "New Article")
        Mobility.locale = :ja
        article.title
        expect(article.send(:mobility_text_translations).size).to eq(2)
        article.save
        expect(article.title).to be_nil
        expect(article.reload.send(:mobility_text_translations).size).to eq(1)
      end
    end

    context "with separate string and text translations" do
      before do
        Article.class_eval do
          translates :short_title, backend: :table, class_name: Mobility::ActiveRecord::StringTranslation, association_name: :mobility_string_translations
        end
      end

      it "saves translations correctly" do
        article = Article.create(title: "foo title", short_title: "bar short title")
        expect(article.title).to eq("foo title")
        expect(article.short_title).to eq("bar short title")

        article = Article.first
        expect(article.title).to eq("foo title")
        expect(article.short_title).to eq("bar short title")

        text = Mobility::ActiveRecord::TextTranslation.first
        expect(text.value).to eq("foo title")

        string = Mobility::ActiveRecord::StringTranslation.first
        expect(string.value).to eq("bar short title")
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
            expect(Post.i18n.where(title: "bar post")).to eq([@post2])
          end

          it "returns correct results when query matches multiple records" do
            expect(Post.i18n.where(title: "foo post")).to match_array([@post1, @post5])
          end

          it "returns correct result when querying on translated and untranslated attributes" do
            expect(Post.i18n.where(title: "baz post", published: true)).to eq([@post3])
          end

          it "returns correct result when querying on nil values" do
            post = Post.create(title: nil)
            expect(Post.i18n.where(title: nil)).to eq([post])
          end

          it "uses inner join" do
            expect(Post.i18n.where(title: "foo").to_sql).not_to match(/OUTER/)
          end

          context "with content in different locales" do
            before do
              Mobility.with_locale(:ja) do
                @ja_post1 = Post.create(title: "foo post ja")
                @ja_post2 = Post.create(title: "foo post")
              end
            end

            it "returns correct result when querying on same attribute value in different locale" do
              expect(Post.i18n.where(title: "foo post")).to match_array([@post1, @post5])

              Mobility.with_locale(:ja) do
                expect(Post.i18n.where(title: "foo post ja")).to eq([@ja_post1])
                expect(Post.i18n.where(title: "foo post")).to eq([@ja_post2])
              end
            end

            #TODO: This would be nice, but will be complicated to implement.
            pending "returns correct result using locale accessors in query" do
              expect(Post.i18n.where(title_ja: "foo post ja")).to eq(@ja_post1)
              expect(Post.i18n.where(title_en: "foo post")).to match_array([@post1, @post5])
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
            expect(Post.i18n.where(title: "foo post")).to match_array([@post1, @post2, @post3])
            expect(Post.i18n.where(content: "foo content")).to match_array([@post2, @post3, @post4])
          end

          it "returns correct results querying on two attributes in single where call" do
            expect(Post.i18n.where(title: "foo post", content: "foo content")).to match_array([@post2, @post3])
          end

          it "returns correct results querying on two attributes in separate where calls" do
            expect(Post.i18n.where(title: "foo post").where(content: "foo content")).to match_array([@post2, @post3])
          end

          it "returns correct result querying on two translated attributes and untranslated attribute" do
            expect(Post.i18n.where(title: "foo post", content: "foo content", published: false)).to eq([@post3])
          end

          it "works with nil values" do
            expect(Post.i18n.where(title: "foo post", content: nil)).to eq([@post1])
            post = Post.create
            expect(Post.i18n.where(title: nil, content: nil)).to eq([post])
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
              expect(Post.i18n.where(title: "foo post", content: "foo content")).to match_array([@post2, @post3])

              Mobility.with_locale(:ja) do
                expect(Post.i18n.where(title: "foo post")).to eq([@ja_post2, @ja_post3])
                expect(Post.i18n.where(title: "foo post", content: "foo content")).to eq([@ja_post2])
                expect(Post.i18n.where(title: "foo post ja", content: "foo content ja")).to eq([@ja_post1])
              end
            end
          end
        end

        context "model with two translated attributes on different tables" do
          before do
            Article.class_eval do
              translates :short_title, backend: :table, class_name: Mobility::ActiveRecord::StringTranslation, association_name: :mobility_string_translations
            end
            @article1 = Article.create(title: "foo post", short_title: "bar short 1")
            @article2 = Article.create(title: "foo post", short_title: "bar short 2")
            @article3 = Article.create(                   short_title: "bar short 1")
          end

          it "returns correct result when querying on multiple tables" do
            expect(Article.i18n.where(title: "foo post", short_title: "bar short 2")).to eq([@article2])
            expect(Article.i18n.where(title: nil, short_title: "bar short 2")).to eq([])
            expect(Article.i18n.where(title: nil, short_title: "bar short 1")).to eq([@article3])
          end
        end
      end

      describe ".not" do
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
          expect(Post.i18n.where.not(title: "foo post")).to match_array([@post5, @post6])
        end

        it "works in combination with untranslated attributes" do
          expect(Post.i18n.where.not(title: "foo post", published: true)).to eq([@post6])
        end

        it "works with nil values" do
          expect(Post.i18n.where.not(title: nil)).to match_array([@post1, @post2, @post3, @post5, @post6])

          # we don't need an OUTER join when matching nil values since we're searching for negative matches
          expect(Post.i18n.where.not(title: nil).to_sql).not_to match /OUTER/
        end

        it "extends Post::MobilityWhereChain to handle translated attributes without creating memory leak" do
          expect(Post.const_defined?(:MobilityWhereChain)).to eq(true)
          expect { Post.i18n.where.not(title: "foo") }.not_to change(Post::MobilityWhereChain, :ancestors)
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
  end
end
