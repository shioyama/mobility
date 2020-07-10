require "spec_helper"

describe "Mobility::Backends::Sequel::Hstore", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/hstore"
  extend Helpers::Sequel

  before do
    stub_const 'HstorePost', Class.new(Sequel::Model)
    HstorePost.dataset = DB[:hstore_posts]
    HstorePost.extend Mobility
  end

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, cache: false, **column_options } }

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:hstore_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { HstorePost.translates :title, :content, backend: :hstore, **default_options }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
    include_querying_examples 'HstorePost'
    include_dup_examples 'HstorePost'

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

  context "with dirty plugin applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { HstorePost.translates :title, :content, backend: :hstore, dirty: true, **default_options }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost', column_affix: column_affix
  end
end if defined?(Sequel) && ENV['DB'] == 'postgres'
