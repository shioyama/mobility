require "spec_helper"

describe "Mobility::Backends::Sequel::Jsonb", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/jsonb"
  extend Helpers::Sequel
  before do
    stub_const 'JsonbPost', Class.new(Sequel::Model)
    JsonbPost.dataset = DB[:jsonb_posts]
    JsonbPost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:jsonb_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility.backend_for("title") }

    before { JsonbPost.translates :title, :content, backend: :jsonb, cache: false, presence: false }
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost'
    include_querying_examples 'JsonbPost'
    include_dup_examples 'JsonbPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving" do
        backend = post.mobility.backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:title]).to eq({ "en" => { "foo" => "bar" }})
      end

      shared_examples_for "jsonb translated value" do |name, value|
        it "stores #{name} values" do
          post.title = value
          expect(post.title).to eq(value)
          post.save

          post = JsonbPost.last
          expect(post.title).to eq(value)
        end

        it "queries on #{name} values" do
          skip "arrays treated as array of values, not value to match" if name == :array
          post1 = JsonbPost.create(title: "foo")
          post2 = JsonbPost.create(title: value)

          expect(JsonbPost.i18n.where(title: "foo").first).to eq(post1)
          expect(JsonbPost.i18n.where(title: value).first).to eq(post2)
        end
      end

      it_behaves_like "jsonb translated value", :integer, 1
      it_behaves_like "jsonb translated value", :hash,    { "a" => "b" } do
        before { JsonbPost.create(title: { "a" => "b", "c" => "d" }) }
      end
      it_behaves_like "jsonb translated value", :array,   [1, "a", nil]
    end
  end

  context "with dirty plugin applied" do
    let(:backend) { post.mobility.backend_for("title") }

    before { JsonbPost.translates :title, :content, backend: :jsonb, cache: false, presence: false, dirty: true }
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost'
  end
end if Mobility::Loaded::Sequel && ENV['DB'] == 'postgres'
