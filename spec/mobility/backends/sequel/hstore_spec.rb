require "spec_helper"

describe Mobility::Backends::Sequel::Hstore, orm: :sequel, db: :postgres do
  extend Helpers::Sequel

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:hstore_posts)) do
      include Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before do
      stub_const 'HstorePost', Class.new(Sequel::Model)
      HstorePost.dataset = DB[:hstore_posts]
      HstorePost.include Mobility
      HstorePost.translates :title, :content, backend: :hstore, cache: false
    end
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    #include_serialization_examples 'HstorePost'
    include_querying_examples 'HstorePost'

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
end if Mobility::Loaded::Sequel
