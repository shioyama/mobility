require "spec_helper"

describe Mobility::Backend::ActiveRecord::Columns, orm: :active_record do
  let(:attribute) { "content" }
  let(:options) { {} }
  let(:backend) { described_class.new(comment, attribute, options) }
  let(:comment) do
    Comment.create(content_en: "Good post!",
                   content_ja: "なかなか面白い記事",
                   content_pt_br: "Olá")
  end

  before do
    stub_const 'Comment', Class.new(ActiveRecord::Base)
    Comment.include Mobility
    Comment.translates attribute, backend: :columns, cache: false
  end

  subject { comment }

  describe "#read" do
    it "returns attribute in locale from appropriate column" do
      expect(backend.read(:en)).to eq("Good post!")
      expect(backend.read(:ja)).to eq("なかなか面白い記事")
    end

    it "handles dashed locales" do
      expect(backend.read(:"pt-BR")).to eq("Olá")
    end
  end

  describe "#write" do
    it "assigns to appropriate columnn" do
      backend.write(:en, "Crappy post!")
      backend.write(:ja, "面白くない")
      expect(comment.content_en).to eq("Crappy post!")
      expect(comment.content_ja).to eq("面白くない")
    end

    it "handles dashed locales" do
      backend.write(:"pt-BR", "Olá Olá")
      expect(comment.content_pt_br).to eq "Olá Olá"
    end
  end

  describe "with locale accessors" do
    it "still works as usual" do
      Comment.translates attribute, backend: :columns, cache: false, locale_accessors: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end
  end

  describe "with dirty" do
    it "still works as usual" do
      Comment.translates attribute, backend: :columns, cache: false, dirty: true
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end

    it "tracks changed attributes" do
      Comment.translates attribute, backend: :columns, cache: false, dirty: true
      comment = Comment.new

      expect(comment.content).to eq(nil)
      expect(comment.changed?).to eq(false)
      expect(comment.changed).to eq([])
      expect(comment.changes).to eq({})

      comment.content = "foo"
      expect(comment.content).to eq("foo")
      expect(comment.changed?).to eq(true)
      expect(comment.changed).to eq(["content_en"])
      expect(comment.changes).to eq({ "content_en" => [nil, "foo"] })
    end
  end

  describe "mobility scope (.i18n)" do
    describe ".where" do
      context "querying on translated attribute" do
        before do
          @comment1 = Comment.create(content_en: "Good post!", content_ja: "面白い記事", published: false)
          @comment2 = Comment.create(content_en: "Crappy post!", content_ja: "面白くない!", published: true)
        end

        it "returns correct record when match exists" do
          expect(Mobility.with_locale(:ja) { Comment.i18n.where(content: "面白い記事") }).to eq([@comment1])
        end

        it "works with untranslated attributes" do
          expect(Mobility.with_locale(:ja) { Comment.i18n.where(content: "面白い記事", published: true) }).to eq([])
          expect(Mobility.with_locale(:ja) { Comment.i18n.where(content: "面白い記事", published: false) }).to eq([@comment1])
          expect(Mobility.with_locale(:en) { Comment.i18n.where(content: "Crappy post!", published: true) }).to eq([@comment2])
          expect(Mobility.with_locale(:en) { Comment.i18n.where(content: "Crappy post!", published: false) }).to eq([])
        end
      end
    end

    describe ".not" do
      before do
        @comment1 = Comment.create(content_en: "Good post!", content_ja: "面白い記事", published: false)
        @comment2 = Comment.create(content_en: "Crappy post!", content_ja: "面白くない!", published: true)
      end

      it "returns record without translated attribute value" do
        expect(Comment.i18n.where.not(content: "Good post!")).to eq([@comment2])
      end

      it "works in combination with untranslated attributes" do
        expect(Comment.i18n.where.not(content: "Good post!", published: true)).to eq([])
        expect(Comment.i18n.where.not(content: "Good post!", published: false)).to eq([@comment2])
      end
    end

    describe "Model.i18n.find_by_<translated attribute>" do
      let!(:comment_1) do
        Comment.create(content_en: "Good post!", content_ja: "面白い記事")
      end
      let!(:comment_2) do
        Comment.create(content_en: "Crappy post!", content_ja: "面白くない!")
      end

      it "finds by column with locale suffix" do
        expect(Comment.i18n.find_by_content("Good post!")).to eq(comment_1)
        expect(Comment.i18n.find_by_content("Crappy post!")).to eq(comment_2)
        Mobility.with_locale(:ja) do
          expect(Comment.i18n.find_by_content("面白い記事")).to eq(comment_1)
          expect(Comment.i18n.find_by_content("面白くない!")).to eq(comment_2)
        end
      end

      it "does not return result for other locale" do
        Mobility.with_locale(:ja) do
          expect(Comment.i18n.find_by_content("Good post!")).to be_nil
          expect(Comment.i18n.find_by_content("Crappy post!")).to be_nil
        end
      end

      it "works on a scope" do
        Mobility.locale = :ja
        comment1 = Comment.create(content: "あああ")
        Mobility.locale = :en
        comment2 = Comment.create(content: "foo")
        Mobility.with_locale(:ja) do
          expect(Comment.i18n.all.find_by_content("あああ")).to eq(comment1)
        end
      end
    end
  end
end
