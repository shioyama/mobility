require "spec_helper"

return unless defined?(Sequel) && defined?(PG)

describe "Mobility::Backends::Sequel::Hstore", orm: :sequel, db: :postgres, type: :backend do
  require "mobility/backends/sequel/hstore"

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonbPost.new }

  before do
    stub_const 'HstorePost', Class.new(Sequel::Model)
    HstorePost.dataset = DB[:hstore_posts]
  end

  context "with no plugins applied" do
    include_backend_examples described_class, 'HstorePost'
  end

  context "with basic plugins" do
    plugins :sequel, :reader, :writer

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
    include_dup_examples 'HstorePost'
  end

  context "with query plugin" do
    plugins :sequel, :reader, :writer, :query

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_querying_examples 'HstorePost'

    describe "non-text values" do
      it "converts non-string types to strings when saving" do
        post = HstorePost.new
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[(column_affix % "title").to_sym].to_hash).to eq({ "en" => "{:foo=>:bar}" })
      end
    end
  end

  context "with dirty plugin" do
    plugins :sequel, :reader, :writer, :dirty

    before { translates HstorePost, :title, :content, backend: :hstore, **column_options }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
  end
end
