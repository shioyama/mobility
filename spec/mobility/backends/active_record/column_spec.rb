require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::Column", orm: :active_record, type: :backend do
  require "mobility/backends/active_record/column"

  before { stub_const 'Comment', Class.new(ActiveRecord::Base) }
  let(:attributes) { %w[content author] }
  let(:backend) do
    described_class.build_subclass(Comment, {}).new(comment, attributes.first)
  end
  let(:comment) do
    Comment.create(content_en: "Good post!",
                   content_ja: "なかなか面白い記事",
                   content_pt_br: "Olá")
  end


  context "with no plugins applied" do
    include_backend_examples described_class, 'Comment', "content"
  end

  context "with standard plugins applied" do
    plugins :active_record, :reader, :writer
    before { translates Comment, *attributes, backend: :column }

    subject { comment }

    include_cache_key_examples "Comment", :content

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
      include_dup_examples 'Comment', :content
    end

    describe "with locale accessors" do
      plugins :active_record, :reader, :writer, :locale_accessors

      it "still works as usual" do
        translates Comment, *attributes, backend: :column, locale_accessors: true
        backend.write(:en, "Crappy post!")
        expect(comment.content_en).to eq("Crappy post!")
      end
    end
  end

  context "with dirty plugin" do
    plugins :active_record, :reader, :writer, :dirty
    before { translates Comment, *attributes, backend: :column }

    it "still works as usual" do
      translates Comment, *attributes, backend: :column
      backend.write(:en, "Crappy post!")
      expect(comment.content_en).to eq("Crappy post!")
    end

    it "tracks changed attributes" do
      translates Comment, *attributes, backend: :column
      comment = Comment.new

      aggregate_failures do
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

    it "returns nil for locales with no column defined" do
      translates Comment, *attributes, backend: :column
      comment = Comment.new

      expect(comment.content(locale: :fr)).to eq(nil)
    end
  end

  describe "with query plugin" do
    plugins :active_record, :reader, :writer, :query
    before { translates Comment, *attributes, backend: :column }

    include_querying_examples 'Comment', :content, :author
    include_validation_examples 'Comment', :content, :author
  end
end
