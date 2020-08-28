require "spec_helper"

return unless defined?(Sequel)

describe "Mobility::Backends::Sequel::Serialized", orm: :sequel, type: :backend do
  require "mobility/backends/sequel/serialized"

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  before do
    stub_const 'SerializedPost', Class.new(Sequel::Model)
    SerializedPost.dataset = DB[:serialized_posts]
  end

  let(:backend) { backend_for(post, :title) }
  let(:post) { SerializedPost.new }

  context "with no options applied" do
    include_backend_examples described_class, 'SerializedPost'
  end

  context "with basic options" do
    plugins :sequel, :reader, :writer

    context "yaml format" do
      before { translates SerializedPost, :title, :content, backend: :serialized, **column_options }

      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost', column_affix: column_affix
      include_dup_examples 'SerializedPost'

      describe "non-text values" do
        it "converts non-string types to strings when saving" do
          backend.write(:en, { foo: :bar } )
          post.save
          expect(post[(column_affix % "title").to_sym]).to eq({ en: "{:foo=>:bar}" }.to_yaml)
        end
      end

      it "does not cache reads" do
        expect(backend).to receive(:translations).twice.and_call_original
        2.times { backend.read(:en) }
      end

      it "re-reads serialized attribute for every write" do
        expect(backend).to receive(:translations).twice.and_call_original
        2.times { backend.write(:en, "foo") }
      end
    end

    context "json format" do
      before { translates SerializedPost, :title, :content, backend: :serialized, format: :json, **column_options }

      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost', column_affix: column_affix

      describe "non-text values" do
        it "converts non-string types to strings when saving" do
          backend.write(:en, { foo: :bar } )
          post.save
          expect(post[(column_affix % "title").to_sym]).to eq({ en: "{:foo=>:bar}" }.to_json)
        end
      end
    end
  end

  context "with cache plugin" do
    plugins :sequel, :reader, :writer, :cache
    before { translates SerializedPost, :title, :content, backend: :serialized, **column_options }

    include_accessor_examples 'SerializedPost'
    include_serialization_examples 'SerializedPost', column_affix: column_affix

    it "uses cache for reads" do
      expect(backend).to receive(:translations).once.and_call_original
      2.times { backend.read(:en) }
    end
  end

  context "with query plugin" do
    plugins :sequel, :reader, :writer, :query
    before { translates SerializedPost, :title, backend: :serialized, **column_options }

    def error_msg(*attributes)
      "You cannot query on mobility attributes translated with the Serialized backend (#{attributes.join(", ")})."
    end

    describe ".where" do
      # need cache for spec that includes key_value backend
      plugins :sequel, :reader, :writer, :query, :cache

      it "raises error for queries on attributes translated with serialized backend" do
        expect { SerializedPost.i18n.where(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
      end

      it "does not raise error for queries on attributes translated with other backends" do
        translates SerializedPost, :subtitle, backend: :key_value, type: :text

        post = SerializedPost.create(subtitle: "foo")
        expect(SerializedPost.i18n.where(subtitle: "foo").select_all(:serialized_posts).all).to eq([post])
      end

      it "does not raise error for queries on untranslated attributes" do
        post = SerializedPost.create(published: true)
        expect(SerializedPost.i18n.where(published: true).select_all(:serialized_posts).all).to eq([post])
      end

      it "raises error with multiple serialized attributes defined separatly" do
        translates SerializedPost, :content, backend: :serialized, **column_options
        expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
        expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
      end
    end
  end
end
