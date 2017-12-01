require "spec_helper"

describe "Mobility::Backends::Sequel::Hstore", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/hstore"
  extend Helpers::Sequel

  before do
    stub_const 'HstorePost', Class.new(Sequel::Model)
    HstorePost.dataset = DB[:hstore_posts]
    HstorePost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:hstore_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before { HstorePost.translates :title, :content, backend: :hstore, cache: false }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    #include_serialization_examples 'HstorePost'
    include_querying_examples 'HstorePost'
    include_dup_examples 'HstorePost'

    describe "non-text values" do
      it "converts non-string types to strings when saving" do
        post = HstorePost.new
        backend = post.mobility_backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:title].to_hash).to eq({ "en" => "{:foo=>:bar}" })
      end
    end
  end

  context "with dirty plugin applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before { HstorePost.translates :title, :content, backend: :hstore, cache: false, presence: false, dirty: true }
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost'
  end
end if Mobility::Loaded::Sequel && ENV['DB'] == 'postgres'
