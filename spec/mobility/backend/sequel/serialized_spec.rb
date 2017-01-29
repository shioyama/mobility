require "spec_helper"

describe Mobility::Backend::Sequel::Serialized, orm: :sequel do
  extend Helpers::Sequel

  before do
    stub_const 'SerializedPost', Class.new(Sequel::Model)
    SerializedPost.dataset = DB[:serialized_posts]
    SerializedPost.include Mobility
  end

  describe "serialized backend without cache" do
    context "yaml format" do
      before { SerializedPost.translates :title, :content, backend: :serialized, format: :yaml, cache: false }
      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost'

      describe "non-text values" do
        it "converts non-string types to strings when saving" do
          post = SerializedPost.new
          backend = post.title_translations
          backend.write(:en, { foo: :bar } )
          post.save
          expect(post.title_before_mobility).to eq({ en: "{:foo=>:bar}" }.to_yaml)
        end
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

    context "json format" do
      before { SerializedPost.translates :title, :content, backend: :serialized, format: :json, cache: false }
      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost'

      describe "non-text values" do
        it "converts non-string types to strings when saving" do
          post = SerializedPost.new
          backend = post.title_translations
          backend.write(:en, { foo: :bar } )
          post.save
          expect(post.title_before_mobility).to eq({ en: "{:foo=>:bar}" }.to_json)
        end
      end

    end
  end

  describe "serialized backend with cache" do
    before { SerializedPost.translates :title, :content, backend: :serialized }
    include_accessor_examples 'SerializedPost'
    include_serialization_examples 'SerializedPost'

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

    def error_msg(*attributes)
      "You cannot query on mobility attributes translated with the Serialized backend (#{attributes.join(", ")})."
    end

    describe ".where" do
      it "raises error for queries on attributes translated with serialized backend" do
        expect { SerializedPost.i18n.where(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
      end

      it "does not raise error for queries on attributes translated with other backends" do
        SerializedPost.translates :subtitle, backend: :key_value

        post = SerializedPost.create(subtitle: "foo")
        expect(SerializedPost.i18n.where(subtitle: "foo").select_all(:serialized_posts).all).to eq([post])
      end

      it "does not raise error for queries on untranslated attributes" do
        post = SerializedPost.create(published: true)
        expect(SerializedPost.i18n.where(published: true).select_all(:serialized_posts).all).to eq([post])
      end

      it "raises error with multiple serialized attributes defined separatly" do
        SerializedPost.translates :content, backend: :serialized
        expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
        expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
      end
    end
  end
end
