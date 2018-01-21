require "spec_helper"

describe "Mobility::Backends::Sequel::Container", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/container"
  extend Helpers::Sequel
  before do
    stub_const 'ContainerPost', Class.new(Sequel::Model)
    ContainerPost.dataset = DB[:container_posts]
    ContainerPost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:container_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before { ContainerPost.translates :title, :content, backend: :container, presence: false, cache: false }
    let(:post) { ContainerPost.new }

    include_accessor_examples 'ContainerPost'
    include_querying_examples 'ContainerPost'
    include_dup_examples 'ContainerPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving" do
        backend = post.mobility_backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:translations]).to eq({ "en" => { "title" => { "foo" => "bar" }}})
      end

      shared_examples_for "jsonb translated value" do |name, value|
        it "stores #{name} values" do
          post.title = value
          expect(post.title).to eq(value)
          post.save

          post = ContainerPost.first
          expect(post.title).to eq(value)
        end

        it "queries on #{name} values" do
          skip "arrays treated as array of values, not value to match" if name == :array
          post1 = ContainerPost.create(title: "foo")
          post2 = ContainerPost.create(title: value)

          expect(ContainerPost.i18n.where(title: "foo").first).to eq(post1)
          expect(ContainerPost.i18n.where(title: value).first).to eq(post2)
        end
      end

      it_behaves_like "jsonb translated value", :integer, 1
      it_behaves_like "jsonb translated value", :hash,    { "a" => "b" }
      it_behaves_like "jsonb translated value", :array,   [1, "a", nil]
    end
  end
end if Mobility::Loaded::Sequel && ENV['DB'] == 'postgres'
