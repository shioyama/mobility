require "spec_helper"

describe "Mobility::Backends::Sequel::Serialized", orm: :sequel do
  require "mobility/backends/sequel/serialized"
  extend Helpers::Sequel

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, **column_options } }

  context "with no options applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:serialized_posts)) do
      extend Mobility
    end)
  end

  context "with standard options applied" do
    before do
      stub_const 'SerializedPost', Class.new(Sequel::Model)
      SerializedPost.dataset = DB[:serialized_posts]
      SerializedPost.extend Mobility
    end

    describe "serialized backend without cache" do
      context "yaml format" do
        before { SerializedPost.translates :title, :content, backend: :serialized, cache: false, **default_options }
        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost', column_affix: column_affix
        include_dup_examples 'SerializedPost'

        describe "non-text values" do
          it "converts non-string types to strings when saving" do
            post = SerializedPost.new
            backend = post.mobility_backends[:title]
            backend.write(:en, { foo: :bar } )
            post.save
            expect(post[(column_affix % "title").to_sym]).to eq({ en: "{:foo=>:bar}" }.to_yaml)
          end
        end

        it "does not cache reads" do
          post = SerializedPost.new
          backend = post.mobility_backends[:title]
          expect(backend).to receive(:translations).twice.and_call_original
          2.times { backend.read(:en) }
        end

        it "re-reads serialized attribute for every write" do
          post = SerializedPost.new
          backend = post.mobility_backends[:title]
          expect(backend).to receive(:translations).twice.and_call_original
          2.times { backend.write(:en, "foo") }
        end
      end

      context "json format" do
        before { SerializedPost.translates :title, :content, backend: :serialized, format: :json, cache: false, **default_options }
        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost', column_affix: column_affix

        describe "non-text values" do
          it "converts non-string types to strings when saving" do
            post = SerializedPost.new
            backend = post.mobility_backends[:title]
            backend.write(:en, { foo: :bar } )
            post.save
            expect(post[(column_affix % "title").to_sym]).to eq({ en: "{:foo=>:bar}" }.to_json)
          end
        end

      end
    end

    describe "serialized backend with cache" do
      before { SerializedPost.translates :title, :content, backend: :serialized, **default_options }
      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost', column_affix: column_affix

      it "uses cache for reads" do
        post = SerializedPost.new
        backend = post.mobility_backends[:title]
        expect(backend).to receive(:translations).once.and_call_original
        2.times { backend.read(:en) }
      end
    end

    describe "mobility scope (.i18n)" do
      before { SerializedPost.translates :title, backend: :serialized, **default_options }

      def error_msg(*attributes)
        "You cannot query on mobility attributes translated with the Serialized backend (#{attributes.join(", ")})."
      end

      describe ".where" do
        it "raises error for queries on attributes translated with serialized backend" do
          expect { SerializedPost.i18n.where(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
        end

        it "does not raise error for queries on attributes translated with other backends" do
          SerializedPost.translates :subtitle, backend: :key_value, type: :text

          post = SerializedPost.create(subtitle: "foo")
          expect(SerializedPost.i18n.where(subtitle: "foo").select_all(:serialized_posts).all).to eq([post])
        end

        it "does not raise error for queries on untranslated attributes" do
          post = SerializedPost.create(published: true)
          expect(SerializedPost.i18n.where(published: true).select_all(:serialized_posts).all).to eq([post])
        end

        it "raises error with multiple serialized attributes defined separatly" do
          SerializedPost.translates :content, backend: :serialized, **default_options
          expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
          expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
        end
      end
    end
  end
end if defined?(Sequel)
