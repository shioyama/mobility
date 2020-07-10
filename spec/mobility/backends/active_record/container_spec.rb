require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Container", orm: :active_record, db: :postgres do
  require "mobility/backends/active_record/container"
  extend Helpers::ActiveRecord
  before do
    stub_const 'ContainerPost', Class.new(ActiveRecord::Base)
    ContainerPost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      extend Mobility
      self.table_name = 'container_posts'
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { ContainerPost.translates :title, :content, backend: :container, presence: false, cache: false }
    let(:post) { ContainerPost.new }

    include_accessor_examples 'ContainerPost'
    include_querying_examples 'ContainerPost'
    include_validation_examples 'ContainerPost'
    include_dup_examples 'ContainerPost'
    include_cache_key_examples 'ContainerPost'

    it "uses existence operator instead of NULL match" do
      aggregate_failures do
        expect(ContainerPost.i18n.where(title: nil).to_sql).to match /\?/
        expect(ContainerPost.i18n.where(title: nil).to_sql).not_to match /NULL/
      end
    end

    it "treats array of nils like nil" do
      expect(ContainerPost.i18n.where(title: nil).to_sql).to eq(ContainerPost.i18n.where(title: [nil]).to_sql)
    end

    describe "non-text values" do
      it "stores non-string types as-is when saving", rails_version_geq: '5.0' do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[:translations]).to eq({ "en" => { "title" => { "foo" => "bar" }}})
      end

      shared_examples_for "container translated value" do |name, value|
        it "stores #{name} values" do
          post.title = value
          expect(post.title).to eq(value)
          post.save

          post = ContainerPost.last
          expect(post.title).to eq(value)
        end

        it "queries on #{name} values" do
          post1 = ContainerPost.create(title: "foo")
          post2 = ContainerPost.create(title: value)

          expect(ContainerPost.i18n.find_by(title: "foo")).to eq(post1)

          # Need to query on [["foo"]] for arrays, otherwise treated as set of
          # values for IN.
          value = [value] if Array === value
          expect(ContainerPost.i18n.find_by(title: value)).to eq(post2)
        end

        it "uses -> operator when in a predicate with other jsonb column" do
          expect(ContainerPost.i18n { title.eq(content) }.to_sql).not_to match("->>")
        end
      end

      it_behaves_like "container translated value", :integer, 1
      it_behaves_like "container translated value", :hash,    { "a" => "b" } do
        before { ContainerPost.create(title: { "a" => "b", "c" => "d" }) }
      end
      it_behaves_like "container translated value", :array,   [1, "a", nil]
    end
  end

  context "with a json column" do
    before(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.create_table :json_container_posts do |t|
        t.json :json_translations, default: {}, null: false
        t.boolean :published
        t.timestamps null: false
      end
    end
    before(:each) do
      stub_const 'JsonContainerPost', Class.new(ActiveRecord::Base)
      JsonContainerPost.extend Mobility
      JsonContainerPost.translates :title, :content, backend: :container, presence: false, cache: false, column_name: :json_translations
    end
    after(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.drop_table :json_container_posts
    end
    include_accessor_examples 'JsonContainerPost'
    include_querying_examples 'JsonContainerPost' unless ENV['RAILS_VERSION'] < '5.0'
  end

  context "with a non-json/jsonb column" do
    before(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.create_table :string_column_posts do |t|
        t.string :foo
        t.boolean :published
        t.timestamps null: false
      end
    end
    after(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.drop_table :string_column_posts
    end

    describe ".build_node" do
      it "raises InvalidColumnType exception when called with column_type" do
        stub_const 'StringColumnPost', Class.new(ActiveRecord::Base)
        StringColumnPost.extend Mobility
        StringColumnPost.translates :title, backend: :container, column_name: :foo
        expect {
          StringColumnPost.mobility_backend_class(:title).build_node(:title, :en)
        }.to raise_error(Mobility::Backends::ActiveRecord::Container::InvalidColumnType,
                         "foo must be a column of type json or jsonb")
      end
    end
  end
end if defined?(ActiveRecord)
