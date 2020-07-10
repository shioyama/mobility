require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Hstore", orm: :active_record, db: :postgres do
  require "mobility/backends/active_record/hstore"
  extend Helpers::ActiveRecord
  before do
    stub_const 'HstorePost', Class.new(ActiveRecord::Base)
    HstorePost.extend Mobility
  end

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, cache: false, **column_options } }

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      extend Mobility
      self.table_name = 'hstore_posts'
    end), column_options
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { HstorePost.translates :title, :content, backend: :hstore, **default_options }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
    include_querying_examples 'HstorePost'
    include_validation_examples 'HstorePost'
    include_dup_examples 'HstorePost'
    include_cache_key_examples 'HstorePost'

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

  context "with dirty plugin applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { HstorePost.translates :title, :content, backend: :hstore, **default_options, dirty: true }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
  end
end if defined?(ActiveRecord)
