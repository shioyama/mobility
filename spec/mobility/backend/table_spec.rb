require "spec_helper"

describe Mobility::Backend::Table do
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
        ].each { |attrs| Mobility::ActiveRecord::Translation.create!(attrs) }
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
        }.to change(subject.send(:mobility_translations), :size).by(1)
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
          }.to change(subject.send(:mobility_translations), :size).by(1)

          expect { subject.save! }.to change(Mobility::ActiveRecord::Translation, :count).by(1)
        end

        it "assigns attributes to translation" do
          title_backend.write(:en, "New Article")

          translation = subject.send(:mobility_translations).first
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New Article")
          expect(translation.translatable).to eq(subject)
        end
      end

      context "translation for locale exists" do
        before do
          Mobility::ActiveRecord::Translation.create!(
            key: "title",
            value: "foo",
            locale: "en",
            translatable: subject
          )
        end

        it "does not create new translation for locale" do
          expect {
            title_backend.write(:en, "New Article")
          }.not_to change(subject.send(:mobility_translations), :size)
        end

        it "updates value attribute on existing translation" do
          title_backend.write(:en, "New New Article")
          subject.save!
          subject.reload

          translation = subject.send(:mobility_translations).first
          expect(translation.key).to eq("title")
          expect(translation.value).to eq("New New Article")
          expect(translation.translatable).to eq(subject)
        end

        it "removes translation if assigned nil when record is saved" do
          expect {
            title_backend.write(:en, nil)
          }.not_to change(subject.send(:mobility_translations), :count)

          expect {
            subject.save!
          }.to change(subject.send(:mobility_translations), :count).by(-1)
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

    it "marks translations association as private" do
      article = Article.create(title: "title")
      expect { article.mobility_translations }.to raise_error(NoMethodError)
      expect { article.send(:mobility_translations) }.not_to raise_error
    end

    describe "creating a new record with translations" do
      it "creates record and translation in current locale" do
        Mobility.locale = :en
        article = Article.create(title: "New Article", content: "Once upon a time...")
        expect(Article.count).to eq(1)
        expect(Mobility::ActiveRecord::Translation.count).to eq(2)
        expect(article.send(:mobility_translations).size).to eq(2)
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
        expect(Mobility::ActiveRecord::Translation.count).to eq(4)
        expect(article.send(:mobility_translations).size).to eq(4)
      end

      it "builds nil translations when reading but does not save them" do
        Mobility.locale = :en
        article = Article.create(title: "New Article")
        Mobility.locale = :ja
        article.title
        expect(article.send(:mobility_translations).size).to eq(2)
        article.save
        expect(article.title).to be_nil
        expect(article.reload.send(:mobility_translations).size).to eq(1)
      end
    end
  end
end
