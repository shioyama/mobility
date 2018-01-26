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
    let(:backend) { post.mobility.backend_for("title") }

    before { ContainerPost.translates :title, :content, backend: :container, presence: false, cache: false }
    let(:post) { ContainerPost.new }

    include_accessor_examples 'ContainerPost'
    include_querying_examples 'ContainerPost'
    include_validation_examples 'ContainerPost'
    include_dup_examples 'ContainerPost'
    include_cache_key_examples 'ContainerPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving", rails_version_geq: '5.0' do
        backend = post.mobility.backend_for("title")
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
          skip "arrays treated as array of values, not value to match" if name == :array
          post1 = ContainerPost.create(title: "foo")
          post2 = ContainerPost.create(title: value)

          expect(ContainerPost.i18n.find_by(title: "foo")).to eq(post1)
          expect(ContainerPost.i18n.find_by(title: value)).to eq(post2)
        end
      end

      it_behaves_like "container translated value", :integer, 1
      it_behaves_like "container translated value", :hash,    { "a" => "b" } do
        before { ContainerPost.create(title: { "a" => "b", "c" => "d" }) }
      end
      it_behaves_like "container translated value", :array,   [1, "a", nil]
    end
  end

  context "with a different column_name" do
    before(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.create_table :foo_posts do |t|
        t.jsonb :foo, default: (::ActiveRecord::VERSION::STRING < '5.0' ? '{}' : '')
        t.boolean :published
        t.timestamps
      end
    end
    before(:each) do
      stub_const 'FooPost', Class.new(ActiveRecord::Base)
      FooPost.extend Mobility
      FooPost.translates :title, :content, backend: :container, presence: false, cache: false, column_name: :foo
    end
    after(:all) do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.drop_table :foo_posts
    end
    include_accessor_examples 'FooPost'
    include_querying_examples 'FooPost'
  end
end if Mobility::Loaded::ActiveRecord
