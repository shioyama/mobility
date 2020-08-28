require "spec_helper"

return unless defined?(Sequel) && defined?(PG)

describe "Mobility::Backends::Sequel::Jsonb", orm: :sequel, db: :postgres, type: :backend do
  require "mobility/backends/sequel/jsonb"

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  before do
    stub_const 'JsonbPost', Class.new(Sequel::Model)
    JsonbPost.dataset = DB[:jsonb_posts]
  end

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonbPost.new }

  context "with no plugins" do
    include_backend_examples described_class, 'JsonbPost', column_options
  end

  context "with basic plugins" do
    plugins :sequel, :reader, :writer
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix
    include_dup_examples 'JsonbPost'
  end

  context "with query plugin" do
    plugins :sequel, :reader, :writer, :query
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_querying_examples 'JsonbPost'

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

  context "with dirty plugin" do
    plugins :sequel, :reader, :writer, :dirty
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix
  end
end
