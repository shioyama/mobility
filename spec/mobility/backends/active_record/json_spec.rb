require "spec_helper"

return unless defined?(ActiveRecord)

describe "Mobility::Backends::ActiveRecord::Json", orm: :active_record, db: [:mysql, :postgres], type: :backend do
  require "mobility/backends/active_record/json"

  before { stub_const 'JsonPost', Class.new(ActiveRecord::Base) }

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonPost.new }

  context "with no plugins" do
    include_backend_examples described_class, 'JsonPost', column_options
  end

  context "with basic plugins" do
    plugins :active_record, :reader, :writer
    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
    include_dup_examples 'JsonPost'
    include_cache_key_examples 'JsonPost'

    it "does not impact dirty tracking on original column" do
      post = JsonPost.create!
      post.reload

      expect([nil, {}]).to include(post.my_title_i18n)
      expect(post.changes).to eq({})
    end

    describe "non-text values" do
      it "stores non-string types as-is when saving", active_record_geq: '5.0' do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[column_affix % "title"]).to eq({ "en" => { "foo" => "bar" }})
      end
    end
  end

  context "with query plugin" do
    plugins :active_record, :reader, :writer, :query
    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_querying_examples 'JsonPost' unless ActiveRecord::VERSION::MAJOR < 5
    include_validation_examples 'JsonPost'
  end

  context "with dirty plugin" do
    plugins :active_record, :reader, :writer, :dirty
    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
  end
end
