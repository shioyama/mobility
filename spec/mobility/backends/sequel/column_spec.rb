require "spec_helper"

describe "Mobility::Backends::Sequel::Column", orm: :sequel do
  require "mobility/backends/sequel/column"
  extend Helpers::Sequel

  context "with no plugins applied" do
    model_class = Class.new(Sequel::Model(:comments)) do
      extend Mobility
    end

    include_backend_examples described_class, model_class, :content
  end

  context "with standard plugins applied" do
    let(:attributes) { %w[content author] }
    let(:backend) { described_class.new(comment, attributes.first) }
    let(:comment) do
      Comment.create(content_en: "Good post!",
                     content_ja: "なかなか面白い記事",
                     content_pt_br: "Olá")
    end

    before do
      stub_const 'Comment', Class.new(Sequel::Model)
      Comment.dataset = DB[:comments]
      Comment.extend Mobility
      Comment.translates *attributes, backend: :column, cache: false
    end

    subject { comment }

    describe "#read" do
      it "returns attribute in locale from appropriate column" do
        aggregate_failures do
          expect(backend.read(:en)).to eq("Good post!")
          expect(backend.read(:ja)).to eq("なかなか面白い記事")
        end
      end

      it "handles dashed locales" do
        expect(backend.read(:"pt-BR")).to eq("Olá")
      end
    end

    describe "#write" do
      it "assigns to appropriate columnn" do
        backend.write(:en, "Crappy post!")
        backend.write(:ja, "面白くない")

        aggregate_failures do
          expect(comment.content_en).to eq("Crappy post!")
          expect(comment.content_ja).to eq("面白くない")
        end
      end

      it "handles dashed locales" do
        backend.write(:"pt-BR", "Olá Olá")
        expect(comment.content_pt_br).to eq "Olá Olá"
      end
    end

    describe "Model accessors" do
      include_accessor_examples 'Comment', :content, :author
    end

    describe "with locale accessors" do
      it "still works as usual" do
        Comment.translates *attributes, backend: :column, cache: false, locale_accessors: true
        backend.write(:en, "Crappy post!")
        expect(comment.content_en).to eq("Crappy post!")
      end
    end

    describe "with dirty" do
      it "still works as usual" do
        Comment.translates *attributes, backend: :column, cache: false, dirty: true
        backend.write(:en, "Crappy post!")
        expect(comment.content_en).to eq("Crappy post!")
      end

      it "tracks changed attributes" do
        Comment.translates *attributes, backend: :column, cache: false, dirty: true
        comment = Comment.new

        aggregate_failures do
          expect(comment.content).to eq(nil)
          comment.column_changed?(:content)
          expect(comment.column_changed?(:content)).to eq(false)
          expect(comment.column_change(:title)).to eq(nil)
          expect(comment.changed_columns).to eq([])
          expect(comment.column_changes).to eq({})

          comment.content = "foo"
          expect(comment.content).to eq("foo")
          expect(comment.column_changed?(:content)).to eq(true)
          expect(comment.column_change(:content)).to eq([nil, "foo"])
          expect(comment.changed_columns).to eq([:content_en])
          expect(comment.column_changes).to eq({ :content_en => [nil, "foo"] })
        end
      end

      it "returns nil for locales with no column defined" do
        Comment.translates *attributes, backend: :column, cache: false, dirty: true
        comment = Comment.new

        expect(comment.content(locale: :fr)).to eq(nil)
      end
    end

    describe "mobility dataset (.i18n)" do
      include_querying_examples 'Comment', :content, :author
    end

    describe "dup" do
      include_dup_examples 'Comment', :content
    end
  end
end if defined?(Sequel)
