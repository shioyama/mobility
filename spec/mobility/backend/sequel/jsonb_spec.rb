require "spec_helper"

describe Mobility::Backend::Sequel::Jsonb, orm: :sequel, db: :postgres do
  extend Helpers::Sequel

  let(:backend) { post.mobility_backend_for("title") }

  before do
    stub_const 'JsonbPost', Class.new(Sequel::Model)
    JsonbPost.dataset = DB[:jsonb_posts]
    JsonbPost.include Mobility
    JsonbPost.translates :title, :content, backend: :jsonb, cache: false
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
      expect(post.title_before_mobility).to eq({ "en" => { "foo" => "bar" }})
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
