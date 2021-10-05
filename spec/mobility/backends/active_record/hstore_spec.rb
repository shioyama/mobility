require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::Hstore", orm: :active_record, db: :postgres, type: :backend do
  require "mobility/backends/active_record/hstore"

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { HstorePost.new }

  before { stub_const 'HstorePost', Class.new(ActiveRecord::Base) }

  context "with no plugins" do
    include_backend_examples described_class, 'HstorePost', column_options
  end

  context "with basic plugins" do
    plugins :active_record, :reader, :writer

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
    include_dup_examples 'HstorePost'
    include_cache_key_examples 'HstorePost'

    it "does not impact dirty tracking on original column" do
      post = HstorePost.create!
      post.reload

      expect(post.my_title_i18n).to eq({})
      expect(post.changes).to eq({})
    end

    describe "non-text values" do
      it "converts non-string types to strings when saving" do
        post = HstorePost.new
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[column_affix % "title"]).to match_hash({ en: "{:foo=>:bar}" })
      end
    end
  end

  context "with query plugin" do
    plugins :active_record, :reader, :writer, :query

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_querying_examples 'HstorePost'
    include_validation_examples 'HstorePost'
  end

  context "with dirty plugin" do
    plugins :active_record, :reader, :writer, :dirty

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
  end
end
