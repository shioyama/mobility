require "spec_helper"

describe "Mobility::Backends::Sequel::Jsonb", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/jsonb"
  extend Helpers::Sequel

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:jsonb_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before do
      stub_const 'JsonbPost', Class.new(Sequel::Model)
      JsonbPost.dataset = DB[:jsonb_posts]
      JsonbPost.extend Mobility
      JsonbPost.translates :title, :content, backend: :jsonb, cache: false, presence: false
    end
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost'
    include_querying_examples 'JsonbPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving" do
        post = JsonbPost.new
        backend = post.mobility_backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:title]).to eq({ "en" => { "foo" => "bar" }})
      end

      it "stores integer values" do
        post.title = 1
        expect(post.title).to eq(1)
        post.save

        post = JsonbPost.first
        expect(post.title).to eq(1)
      end
    end
  end
end if Mobility::Loaded::Sequel
