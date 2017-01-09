require "spec_helper"

describe Mobility::Backend::ActiveRecord::Serialized, orm: :active_record do
  let(:backend) { post.title_translations }

  before do
    stub_const 'SerializedPost', Class.new(ActiveRecord::Base)
    SerializedPost.include Mobility
  end

  subject { post }

  shared_examples_for "serialized backend" do
    describe "#read" do
      context "with nil serialized column" do
        let(:post) { SerializedPost.new }

        it "returns nil in any locale" do
          expect(backend.read(:en)).to eq(nil)
          expect(backend.read(:ja)).to eq(nil)
        end
      end

      context "with serialized column" do
        let(:post) do
          post = SerializedPost.new
          post.write_attribute(:title, { ja: "あああ" })
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
          post.write_attribute(:title, { ja: "あああ" })
          post.write_attribute(:content, { en: "aaa" })
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
        expect(subject.read_attribute(:title)).to eq({ en: "foo" })
        backend.write(:fr, "bar")
        expect(subject.read_attribute(:title)).to eq({ en: "foo", fr: "bar" })
      end

      it "deletes keys with nil values when saving" do
        backend.write(:en, "foo")
        expect(subject.read_attribute(:title)).to eq({ en: "foo" })
        backend.write(:en, nil)
        expect(subject.read_attribute(:title)).to eq({ en: nil })
        subject.save
        expect(backend.read(:en)).to eq(nil)
        expect(subject.read_attribute(:title)).to eq({})
      end

      it "deletes keys with blank values when saving" do
        backend.write(:en, "foo")
        expect(subject.read_attribute(:title)).to eq({ en: "foo" })
        subject.save
        expect(subject.read_attribute(:title)).to eq({ en: "foo" })
        backend.write(:en, "")
        subject.save

        # Note: Sequel backend returns a blank string here.
        expect(backend.read(:en)).to eq(nil)

        expect(subject.title).to eq(nil)
        subject.reload
        expect(backend.read(:en)).to eq(nil)
        expect(subject.read_attribute(:title)).to eq({})
      end

      it "converts non-string types to strings when saving" do
        backend.write(:en, { foo: :bar } )
        subject.save
        expect(subject.read_attribute(:title)).to eq({ en: "{:foo=>:bar}" })
      end

      it "correctly stores serialized attributes" do
        backend.write(:en, "foo")
        backend.write(:fr, "bar")
        subject.save
        post = SerializedPost.first
        expect(post.title).to eq("foo")
        Mobility.with_locale(:fr) { expect(post.title).to eq("bar") }
        expect(post.read_attribute(:title)).to eq({ en: "foo", fr: "bar" })

        backend.write(:en, "")
        subject.save
        post = SerializedPost.first
        expect(post.title).to eq(nil)
        expect(post.read_attribute(:title)).to eq({ fr: "bar" })
      end
    end

    describe "Model#save" do
      let(:post) { SerializedPost.new }

      it "saves empty hash for serialized translations by default" do
        expect(post.title).to eq(nil)
        expect(backend.read(:en)).to eq(nil)
        post.save
        expect(post.read_attribute(:title)).to eq({})
      end

      it "saves changes to translations" do
        subject.title = "foo"
        subject.save
        post = SerializedPost.first
        expect(post.read_attribute(:title)).to eq({ en: "foo" })
      end
    end

    describe "Model#update" do
      let(:post) { SerializedPost.create }

      it "updates changes to translations" do
        subject.title = "foo"
        subject.save
        expect(post.read_attribute(:title)).to eq({ en: "foo" })
        post = SerializedPost.first
        post.update(title: "bar")
        expect(post.read_attribute(:title)).to eq({ en: "bar" })
      end
    end
  end

  describe "serialized backend without cache" do
    context "yaml format" do
      before { SerializedPost.translates :title, :content, backend: :serialized, format: :yaml, cache: false }
      it_behaves_like "serialized backend"

      # SANITY CHECK
      it "serializes as YAML" do
        post = SerializedPost.new
        post.title = "foo"
        post.save
        expect(post.title_before_type_cast).to eq("---\n:en: foo\n")
      end

      it "does not cache reads" do
        post = SerializedPost.new
        backend = post.title_translations
        expect(post).to receive(:read_attribute).twice.and_call_original
        2.times { backend.read(:en) }
      end

      it "re-reads serialized attribute for every write" do
        post = SerializedPost.new
        backend = post.title_translations
        expect(post).to receive(:read_attribute).twice.and_call_original
        2.times { backend.write(:en, "foo") }
      end
    end

    context "json format" do
      before { SerializedPost.translates :title, :content, backend: :serialized, format: :json, cache: false }
      it_behaves_like "serialized backend"

      # SANITY CHECK
      it "serializes as JSON" do
        post = SerializedPost.new
        post.title = "foo"
        post.save
        expect(post.title_before_type_cast).to eq("{\"en\":\"foo\"}")
      end
    end
  end

  describe "serialized backend with cache" do
    before { SerializedPost.translates :title, :content, backend: :serialized }
    it_behaves_like "serialized backend"

    it "uses cache for reads" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(post).to receive(:read_attribute).once.and_call_original
      2.times { backend.read(:en) }
    end

    it "uses cached serialized attribute for writes" do
      post = SerializedPost.new
      backend = post.title_translations
      expect(post).to receive(:read_attribute).once.and_call_original
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
        expect(SerializedPost.i18n.where(subtitle: "foo")).to eq([post])
      end

      it "does not raise error for queries on untranslated attributes" do
        post = SerializedPost.create(published: true)
        expect(SerializedPost.i18n.where(published: true)).to eq([post])
      end

      it "raises error with multiple serialized attributes defined separatly" do
        SerializedPost.translates :content, backend: :serialized
        expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg)
        expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg)
      end
    end

    describe ".not" do
      it "raises an error for queries on attributes translated with serialized backend" do
        expect { SerializedPost.i18n.where.not(title: "foo") }.to raise_error(ArgumentError, error_msg)
      end

      it "does not raise error for queries on attributes translated with other backends" do
        SerializedPost.translates :subtitle, backend: :table

        post = SerializedPost.create(subtitle: "foo")
        expect(SerializedPost.i18n.where.not(subtitle: "bar")).to eq([post])
      end

      it "does not raise error for queries on untranslated attributes" do
        post = SerializedPost.create(published: true)
        expect(SerializedPost.i18n.where.not(published: false)).to eq([post])
      end

      it "raises error with multiple serialized attributes defined separatly" do
        SerializedPost.translates :content, backend: :serialized

        expect { SerializedPost.i18n.where.not(content: "foo") }.to raise_error(ArgumentError, error_msg)
        expect { SerializedPost.i18n.where.not(title: "foo")   }.to raise_error(ArgumentError, error_msg)
      end
    end
  end
end
