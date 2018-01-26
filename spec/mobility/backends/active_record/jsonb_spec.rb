require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Jsonb", orm: :active_record, db: :postgres do
  require "mobility/backends/active_record/jsonb"
  extend Helpers::ActiveRecord
  before do
    stub_const 'JsonbPost', Class.new(ActiveRecord::Base)
    JsonbPost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      extend Mobility
      self.table_name = 'jsonb_posts'
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility.backend_for("title") }

    before { JsonbPost.translates :title, :content, backend: :jsonb, presence: false, cache: false }
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost'
    include_querying_examples 'JsonbPost'
    include_validation_examples 'JsonbPost'
    include_dup_examples 'JsonbPost'
    include_cache_key_examples 'JsonbPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving", rails_version_geq: '5.0' do
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

          expect(JsonbPost.i18n.find_by(title: "foo")).to eq(post1)
          expect(JsonbPost.i18n.find_by(title: value)).to eq(post2)
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
end if Mobility::Loaded::ActiveRecord
