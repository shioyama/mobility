require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Serialized", orm: :active_record do
  require "mobility/backends/active_record/serialized"
  extend Helpers::ActiveRecord

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      extend Mobility
      self.table_name = 'serialized_posts'
    end)
  end

  context "with standard plugins applied" do
    before do
      stub_const 'SerializedPost', Class.new(ActiveRecord::Base)
      SerializedPost.extend Mobility
    end

    describe "serialized backend without cache" do
      context "yaml format" do
        before { SerializedPost.translates :title, :content, backend: :serialized, format: :yaml, cache: false, presence: false }
        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost'
        include_ar_integration_examples 'SerializedPost'

        describe "non-text values" do
          it "converts non-string types to strings when saving", rails_version_geq: '5.0' do
            post = SerializedPost.new
            backend = post.mobility_backend_for("title")
            backend.write(:en, { foo: :bar } )
            post.save
            expect(post.read_attribute(:title)).to match_hash({ en: "{:foo=>:bar}" })
          end
        end

        # SANITY CHECK
        it "serializes as YAML" do
          post = SerializedPost.new
          post.title = "foo"
          post.save
          post.reload if ENV['RAILS_VERSION'] < '5.0' # don't ask me why
          expect(post.title_before_type_cast).to eq("---\n:en: foo\n")
        end

        it "does not cache reads" do
          post = SerializedPost.new
          backend = post.mobility_backend_for("title")
          expect(post).to receive(:read_attribute).twice.and_call_original
          2.times { backend.read(:en) }
        end

        it "re-reads serialized attribute for every write" do
          post = SerializedPost.new
          backend = post.mobility_backend_for("title")
          expect(post).to receive(:read_attribute).twice.and_call_original
          2.times { backend.write(:en, "foo") }
        end
      end

      context "json format" do
        before { SerializedPost.translates :title, :content, backend: :serialized, format: :json, cache: false, presence: false }
        include_accessor_examples 'SerializedPost'
        include_serialization_examples 'SerializedPost'

        # SANITY CHECK
        it "serializes as JSON" do
          post = SerializedPost.new
          post.title = "foo"
          post.save
          post.reload if ENV['RAILS_VERSION'] < '5.0' # don't ask me why
          expect(post.title_before_type_cast).to eq("{\"en\":\"foo\"}")
        end
      end
    end

    describe "serialized backend with cache" do
      before { SerializedPost.translates :title, :content, backend: :serialized, presence: false }
      include_accessor_examples 'SerializedPost'
      include_serialization_examples 'SerializedPost'

      it "uses cache for reads" do
        post = SerializedPost.new
        backend = post.mobility_backend_for("title")
        expect(post).to receive(:read_attribute).once.and_call_original
        2.times { backend.read(:en) }
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
          expect(SerializedPost.i18n.where(subtitle: "foo")).to eq([post])
        end

        it "does not raise error for queries on untranslated attributes" do
          post = SerializedPost.create(published: true)
          expect(SerializedPost.i18n.where(published: true)).to eq([post])
        end

        it "raises error with multiple serialized attributes defined separatly" do
          SerializedPost.translates :content, backend: :serialized
          expect { SerializedPost.i18n.where(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
          expect { SerializedPost.i18n.where(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
        end
      end

      describe ".not" do
        it "raises an error for queries on attributes translated with serialized backend" do
          expect { SerializedPost.i18n.where.not(title: "foo") }.to raise_error(ArgumentError, error_msg("title"))
        end

        it "does not raise error for queries on attributes translated with other backends" do
          SerializedPost.translates :subtitle, backend: :key_value

          post = SerializedPost.create(subtitle: "foo")
          expect(SerializedPost.i18n.where.not(subtitle: "bar")).to eq([post])
        end

        it "does not raise error for queries on untranslated attributes" do
          post = SerializedPost.create(published: true)
          expect(SerializedPost.i18n.where.not(published: false)).to eq([post])
        end

        it "raises error with multiple serialized attributes defined separatly" do
          SerializedPost.translates :content, backend: :serialized

          expect { SerializedPost.i18n.where.not(content: "foo") }.to raise_error(ArgumentError, error_msg("content"))
          expect { SerializedPost.i18n.where.not(title: "foo")   }.to raise_error(ArgumentError, error_msg("title"))
        end
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
