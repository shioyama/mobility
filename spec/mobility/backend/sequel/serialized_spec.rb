require "spec_helper"

describe Mobility::Backend::Sequel::Serialized, orm: :sequel do
  let(:backend) { post.title_translations }

  before do
    stub_const 'SerializedPost', Class.new(Sequel::Model)
    SerializedPost.dataset = DB[:serialized_posts]
    SerializedPost.include Mobility
  end

  subject { post }

  shared_examples_for "serialized backend" do |format|
    describe "#read" do
      context "with nil serialized column" do
        let(:post) { SerializedPost.new }

        it "returns nil in any locale" do
          expect(backend.read(:en)).to eq(nil)
          expect(backend.read(:ja)).to eq(nil)
        end
      end

      context "serialized column has a translation" do
        let(:post) do
          post = SerializedPost.new
          post.title_before_mobility = { ja: "あああ" }.send("to_#{format}")
          post.save
          post.reload
        end

        it "returns translation from serialized hash" do
          expect(backend.read(:ja)).to eq("あああ")
          expect(backend.read(:en)).to eq(nil)
        end
      end

      context "multiple serialized columns have translations" do
        let(:post) do
          post = SerializedPost.new
          post.title_before_mobility = { ja: "あああ" }.send("to_#{format}")
          post.content_before_mobility = { en: "aaa" }.send("to_#{format}")
          post.save
          post.reload
        end

        it "returns translation from serialized hash" do
          expect(backend.read(:ja)).to eq("あああ")
          expect(backend.read(:en)).to eq(nil)
          backend = subject.content_translations
          expect(backend.read(:ja)).to eq(nil)
          expect(backend.read(:en)).to eq("aaa")
        end
      end
    end

    describe "#write" do
      let(:post) { SerializedPost.create }

      it "assigns to serialized hash" do
        backend.write(:en, "foo")
        expect(subject.deserialized_values[:title]).to eq(en: "foo")
        backend.write(:fr, "bar")
        expect(subject.deserialized_values[:title]).to eq({ en: "foo", fr: "bar" })
      end

      it "deletes keys with nil values when saving" do
        backend.write(:en, "foo")
        expect(subject.deserialized_values[:title]).to eq({ en: "foo" })
        backend.write(:en, nil)
        expect(subject.deserialized_values[:title]).to eq({ en: nil })
        subject.save
        expect(backend.read(:en)).to eq(nil)
        expect(subject.title_before_mobility).to eq({}.send("to_#{format}"))
      end

      it "deletes keys with blank values when saving" do
        backend.write(:en, "foo")
        expect(subject.deserialized_values[:title]).to eq({ en: "foo" })
        subject.save
        expect(subject.title_before_mobility).to eq({ en: "foo" }.send("to_#{format}"))
        backend.write(:en, "")
        subject.save

        # Backend continues to return a blank string, but does not save it,
        # because deserialized_values holds the value assigned rather than the
        # value as it was actually serialized.
        #
        # This is different from the ActiveRecord backend, where the serialized
        # value is read back, so the backend returns nil.
        # TODO: Make this return nil? (or make AR return a blank string)
        # (In practice this is not an issue since post.title returns `value.presence`).
        expect(backend.read(:en)).to eq("")

        expect(subject.title).to eq(nil)
        subject.reload
        expect(backend.read(:en)).to eq(nil)
        expect(subject.title_before_mobility).to eq({}.send("to_#{format}"))
      end

      it "converts non-string types to strings when saving" do
        backend.write(:en, { foo: :bar } )
        subject.save
        expect(subject.title_before_mobility).to eq({ en: "{:foo=>:bar}" }.send("to_#{format}"))
      end

      it "correctly stores serialized attributes" do
        backend.write(:en, "foo")
        backend.write(:fr, "bar")
        subject.save
        post = SerializedPost.first
        expect(post.title).to eq("foo")
        Mobility.with_locale(:fr) { expect(post.title).to eq("bar") }
        expect(post.title_before_mobility).to eq({ en: "foo", fr: "bar" }.send("to_#{format}"))

        backend.write(:en, "")
        subject.save
        post = SerializedPost.first
        expect(post.title).to eq(nil)
        expect(post.title_before_mobility).to eq({ fr: "bar" }.send("to_#{format}"))
      end
    end

    describe "Model#save" do
      let(:post) { SerializedPost.new }

      it "saves empty hash for serialized translations by default" do
        expect(post.title).to eq(nil)
        expect(backend.read(:en)).to eq(nil)
        post.save
        expect(post.title_before_mobility).to eq({}.send("to_#{format}"))
      end

      it "saves changes to translations" do
        subject.title = "foo"
        subject.save
        post = SerializedPost.first
        expect(post.title_before_mobility).to eq({ en: "foo" }.send("to_#{format}"))
      end
    end

    describe "Model#update" do
      let(:post) { SerializedPost.create }

      it "updates changes to translations" do
        subject.title = "foo"
        subject.save
        expect(post.title_before_mobility).to eq({ en: "foo" }.send("to_#{format}"))
        post = SerializedPost.first
        post.update(title: "bar")
        expect(post.title_before_mobility).to eq({ en: "bar" }.send("to_#{format}"))
      end
    end
  end

  describe "serialized backend without cache" do
    let(:format) { nil }
    before { SerializedPost.translates :title, :content, backend: :serialized, format: format, cache: false }

    context "yaml format" do
      it_behaves_like "serialized backend", :yaml
    end

    context "json format" do
      let(:format) { :json }
      it_behaves_like "serialized backend", :json
    end

    it "does not cache reads" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(backend).to receive(:translations).twice.and_call_original
      2.times { backend.read(:en) }
    end

    it "re-reads serialized attribute for every write" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(backend).to receive(:translations).twice.and_call_original
      2.times { backend.write(:en, "foo") }
    end
  end

  describe "serialized backend with cache" do
    before { SerializedPost.translates :title, :content, backend: :serialized }
    it_behaves_like "serialized backend", :yaml

    it "uses cache for reads" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(backend).to receive(:translations).once.and_call_original
      2.times { backend.read(:en) }
    end

    it "uses cached serialized attribute for writes" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(backend).to receive(:translations).once.and_call_original
      2.times { backend.write(:en, "foo") }
    end
  end

  describe "mobility scope (.i18n)" do
    before { SerializedPost.translates :title, backend: :serialized }
    let(:error_msg) { "You cannot query on mobility attributes translated with the Serialized backend." }

    describe ".where" do
      it "raises error for queries on attributes translated with serialized backend" do
        expect { SerializedPost.i18n.where(title: "foo") }.to raise_error(ArgumentError, error_msg)
      end

      it "does not raise error for queries on attributes translated with other backends" do
        SerializedPost.translates :subtitle, backend: :table

        post = SerializedPost.create(subtitle: "foo")
        expect(SerializedPost.i18n.where(subtitle: "foo").select_all(:serialized_posts).all).to eq([post])
      end

      it "does not raise error for queries on untranslated attributes" do
        post = SerializedPost.create(published: true)
        expect(SerializedPost.i18n.where(published: true).select_all(:serialized_posts).all).to eq([post])
      end

      it "raises error with multiple serialized attributes defined separatly" do
        SerializedPost.translates :content, backend: :serialized
        expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg)
        expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg)
      end
    end
  end
end
