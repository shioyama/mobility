require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::Jsonb", orm: :active_record, db: :postgres, type: :backend do
  require "mobility/backends/active_record/jsonb"

  before { stub_const 'JsonbPost', Class.new(ActiveRecord::Base) }

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonbPost.new }

  context "with no plugins" do
    include_backend_examples described_class, 'JsonbPost', column_options
  end

  context "with basic plugins" do
    plugins :active_record, :reader, :writer
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix
    include_dup_examples 'JsonbPost'
    include_cache_key_examples 'JsonbPost'

    it "does not impact dirty tracking on original column" do
      post = JsonbPost.create!
      post.reload

      expect(post.my_title_i18n).to eq({})
      expect(post.changes).to eq({})
    end
  end

  context "with query plugin" do
    plugins :active_record, :reader, :writer, :query
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_querying_examples 'JsonbPost'
    include_validation_examples 'JsonbPost'

    it "uses existence operator instead of NULL match" do
      aggregate_failures do
        expect(JsonbPost.i18n.where(title: nil).to_sql).to match /\?/
        expect(JsonbPost.i18n.where(title: nil).to_sql).not_to match /NULL/
      end
    end

    it "treats array of nils like nil" do
      expect(JsonbPost.i18n.where(title: nil).to_sql).to eq(JsonbPost.i18n.where(title: [nil]).to_sql)
    end

    describe "non-text values" do
      it "stores non-string types as-is when saving", active_record_geq: '5.0' do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[column_affix % "title"]).to eq({ "en" => { "foo" => "bar" }})
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
          post1 = JsonbPost.create(title: "foo")
          post2 = JsonbPost.create(title: value)

          expect(JsonbPost.i18n.find_by(title: "foo")).to eq(post1)

          value = [value] if Array === value
          expect(JsonbPost.i18n.find_by(title: value)).to eq(post2)

          # Only use ->> operator when matching strings
          expect(JsonbPost.i18n.where(title: value).to_sql).not_to match("->>")
        end

        it "uses -> operator when in a predicate with other jsonb column" do
          expect(JsonbPost.i18n { title.eq(content) }.to_sql).not_to match("->>")
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
    plugins :active_record, :reader, :writer, :dirty
    before { translates JsonbPost, :title, :content, backend: :jsonb, **column_options }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost', column_affix: column_affix

    # regression for https://github.com/shioyama/mobility/issues/308
    include_querying_examples 'JsonbPost' if ActiveRecord::VERSION::STRING == '5.1'
  end
end
