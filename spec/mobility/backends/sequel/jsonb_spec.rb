require "spec_helper"

describe "Mobility::Backends::Sequel::Jsonb", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/jsonb"
  extend Helpers::Sequel
  before do
    stub_const 'JsonbPost', Class.new(Sequel::Model)
    JsonbPost.dataset = DB[:jsonb_posts]
    JsonbPost.extend Mobility
  end

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, cache: false, **column_options } }

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:jsonb_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { JsonbPost.translates :title, :content, backend: :jsonb, **default_options }
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix
    include_querying_examples 'JsonbPost'
    include_dup_examples 'JsonbPost'

    it "uses existence operator instead of NULL match" do
      aggregate_failures do
        expect(JsonbPost.i18n.where(title: nil).sql).to match /\?/
        expect(JsonbPost.i18n.where(title: nil).sql).not_to match /NULL/
      end
    end

    it "treats array of nils like nil" do
      expect(JsonbPost.i18n.where(title: nil).sql).to eq(JsonbPost.i18n.where(title: [nil]).sql)
    end

    describe "non-text values" do
      it "stores non-string types as-is when saving" do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[(column_affix % "title").to_sym]).to eq({ "en" => { "foo" => "bar" }})
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

          # Only use ->> operator when matching strings
          expect(JsonbPost.i18n.where(title: value).sql).not_to match("->>")
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
    let(:backend) { post.mobility_backends[:title] }

    before { JsonbPost.translates :title, :content, backend: :jsonb, dirty: true, **default_options }
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix
  end
end if defined?(Sequel) && ENV['DB'] == 'postgres'
