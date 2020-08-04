require "spec_helper"

describe "Mobility::Backends::ActiveRecord::Json", orm: :active_record do
  require "mobility/backends/active_record/json"
  extend Helpers::ActiveRecord
  before do
    stub_const 'JsonPost', Class.new(ActiveRecord::Base)
    JsonPost.extend Mobility
  end

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, cache: false, **column_options } }

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      extend Mobility
      self.table_name = 'json_posts'
    end), column_options
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { JsonPost.translates :title, :content, backend: :json, **default_options }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
    include_querying_examples 'JsonPost' unless ENV['RAILS_VERSION'] < '5.0'
    include_validation_examples 'JsonPost'
    include_dup_examples 'JsonPost'
    include_cache_key_examples 'JsonPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving", rails_version_geq: '5.0' do
        backend = post.mobility_backends[:title]
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post[column_affix % "title"]).to eq({ "en" => { "foo" => "bar" }})
      end
    end
  end

  context "with dirty plugin applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { JsonPost.translates :title, :content, backend: :json, **default_options, dirty: true }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
  end
end if Mobility::Loaded::ActiveRecord
