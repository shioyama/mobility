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
    let(:backend) { post.mobility_backends[:title] }

    before { ContainerPost.translates :title, :content, backend: :container, presence: false, cache: false }
    let(:post) { ContainerPost.new }

    include_accessor_examples 'ContainerPost'
    include_querying_examples 'ContainerPost'
    include_dup_examples 'ContainerPost'

    it "uses existence operator instead of NULL match" do
      aggregate_failures do
        expect(ContainerPost.i18n.where(title: nil).sql).to match /\?/
        expect(ContainerPost.i18n.where(title: nil).sql).not_to match /NULL/
      end
    end

    it "treats array of nils like nil" do
      expect(ContainerPost.i18n.where(title: nil).sql).to eq(ContainerPost.i18n.where(title: [nil]).sql)
    end

    describe "non-text values" do
      it "stores non-string types as-is when saving" do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:translations]).to eq({ "en" => { "title" => { "foo" => "bar" }}})
      end

      shared_examples_for "jsonb translated value" do |name, value|
        it "stores #{name} values" do
          post.title = value
          expect(post.title).to eq(value)
          post.save

          post = ContainerPost.last
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
      it_behaves_like "jsonb translated value", :hash,    { "a" => "b" } do
        before { ContainerPost.create(title: { "a" => "b", "c" => "d" }) }
      end
      it_behaves_like "jsonb translated value", :array,   [1, "a", nil]
    end
  end

  context "with a json column_name" do
    before(:all) do
      DB.create_table!(:json_container_posts) { primary_key :id; json :json_translations, default: '{}'; TrueClass :published }
    end
    before(:each) do
      stub_const 'JsonContainerPost', Class.new(Sequel::Model)
      JsonContainerPost.dataset = DB[:json_container_posts]
      JsonContainerPost.extend Mobility
      JsonContainerPost.translates :title, :content, backend: :container, presence: false, cache: false, column_name: :json_translations
    end
    after(:all) { DB.drop_table?(:json_container_posts) }

    include_accessor_examples 'JsonContainerPost'
    include_querying_examples 'JsonContainerPost'
  end

  context "with a non-json/jsonb column" do
    before(:all) do
      DB.create_table!(:string_column_posts) { primary_key :id; String :foo, default: ''; TrueClass :published }
    end
    after(:all) { DB.drop_table?(:string_column_posts) }

    it "raises InvalidColumnType exception" do
      stub_const 'StringColumnPost', Class.new(Sequel::Model)
      StringColumnPost.dataset = DB[:string_column_posts]
      StringColumnPost.extend Mobility
      expect { StringColumnPost.translates :title, backend: :container, column_name: :foo
      }.to raise_error(Mobility::Backends::Sequel::Container::InvalidColumnType,
                       "foo must be a column of type json or jsonb")
    end
  end
end if defined?(Sequel) && ENV['DB'] == 'postgres'
