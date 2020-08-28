require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::Serialized", orm: :active_record, type: :backend do
  require "mobility/backends/active_record/serialized"

  before { stub_const 'SerializedPost', Class.new(ActiveRecord::Base) }

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  context "with no plugins" do
    include_backend_examples described_class, 'SerializedPost', column_options
  end

  context "with basic plugins" do
    plugins :active_record, :reader, :writer

    describe "serialized backend without cache" do
      context "yaml format" do
        before { translates SerializedPost, :title, :content, backend: :serialized, format: :yaml, **column_options }

        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost', column_affix: column_affix
        include_dup_examples 'SerializedPost'
        include_cache_key_examples 'SerializedPost'

        describe "non-text values" do
          it "converts non-string types to strings when saving", active_record_geq: '5.0' do
            post = SerializedPost.new
            backend = post.mobility_backends[:title]
            backend.write(:en, { foo: :bar } )
            post.save
            expect(post[column_affix % "title"]).to match_hash({ en: "{:foo=>:bar}" })
          end
        end

        # SANITY CHECK
        it "serializes as YAML" do
          post = SerializedPost.new
          post.title = "foo"
          post.save
          post.reload if ActiveRecord::VERSION::MAJOR < 5 # don't ask me why
          expect(post.public_send("#{(column_affix % "title")}_before_type_cast")).to eq("---\n:en: foo\n")
        end

        it "does not cache reads" do
          post = SerializedPost.new
          backend = post.mobility_backends[:title]
          expect(post).to receive(:read_attribute).twice.and_call_original
          2.times { backend.read(:en) }
        end

        it "re-reads serialized attribute for every write" do
          post = SerializedPost.new
          backend = post.mobility_backends[:title]
          expect(post).to receive(:read_attribute).twice.and_call_original
          2.times { backend.write(:en, "foo") }
        end
      end

      context "json format" do
        before { translates SerializedPost, :title, :content, backend: :serialized, format: :json, **column_options }
        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost', column_affix: column_affix

        # SANITY CHECK
        it "serializes as JSON" do
          post = SerializedPost.new
          post.title = "foo"
          post.save
          post.reload if ActiveRecord::VERSION::MAJOR < 5 # don't ask me why
          expect(post.public_send("#{column_affix % "title"}_before_type_cast")).to eq("{\"en\":\"foo\"}")
        end
      end
    end

    describe "serialized backend with cache" do
      plugins :active_record, :reader, :writer, :cache
      before { translates SerializedPost, :title, :content, backend: :serialized, **column_options }

      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost', column_affix: column_affix

      it "uses cache for reads" do
        post = SerializedPost.new
        backend = post.mobility_backends[:title]
        expect(post).to receive(:read_attribute).once.and_call_original
        2.times { backend.read(:en) }
      end
    end

    describe "mobility scope (.i18n)" do
      plugins :active_record, :reader, :writer, :query
      before { translates SerializedPost, :title, backend: :serialized, **column_options }

      def error_msg(*attributes)
        "You cannot query on mobility attributes translated with the Serialized backend (#{attributes.join(", ")})."
      end

      describe ".where" do
        it "raises error for queries on attributes translated with serialized backend" do
          expect { SerializedPost.i18n.where(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
        end

        it "does not raise error for queries on attributes translated with other backends" do
          translates SerializedPost, :subtitle, backend: :key_value, type: :text

          post = SerializedPost.create(subtitle: "foo")
          expect(SerializedPost.i18n.where(subtitle: "foo")).to eq([post])
        end

        it "does not raise error for queries on untranslated attributes" do
          post = SerializedPost.create(published: true)
          expect(SerializedPost.i18n.where(published: true)).to eq([post])
        end

        it "raises error with multiple serialized attributes defined separatly" do
          translates SerializedPost, :content, backend: :serialized
          expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
          expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
        end
      end

      describe ".not" do
        it "raises an error for queries on attributes translated with serialized backend" do
          expect { SerializedPost.i18n.where.not(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
        end

        it "does not raise error for queries on attributes translated with other backends" do
          translates SerializedPost, :subtitle, backend: :key_value, type: :text

          post = SerializedPost.create(subtitle: "foo")
          expect(SerializedPost.i18n.where.not(subtitle: "bar")).to eq([post])
        end

        it "does not raise error for queries on untranslated attributes" do
          post = SerializedPost.create(published: true)
          expect(SerializedPost.i18n.where.not(published: false)).to eq([post])
        end

        it "raises error with multiple serialized attributes defined separatly" do
          translates SerializedPost, :content, backend: :serialized

          expect { SerializedPost.i18n.where.not(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
          expect { SerializedPost.i18n.where.not(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
        end
      end
    end
  end
end
