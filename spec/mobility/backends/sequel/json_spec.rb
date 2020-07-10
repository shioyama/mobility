require "spec_helper"

describe "Mobility::Backends::Sequel::Json", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/json"
  extend Helpers::Sequel
  before do
    stub_const 'JsonPost', Class.new(Sequel::Model)
    JsonPost.dataset = DB[:json_posts]
    JsonPost.extend Mobility
  end

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"
  let(:default_options) { { presence: false, cache: false, **column_options } }

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:json_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { JsonPost.translates :title, :content, backend: :json, **default_options }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
    include_querying_examples 'JsonPost'
    include_dup_examples 'JsonPost'
  end

  context "with dirty plugin applied" do
    let(:backend) { post.mobility_backends[:title] }

    before { JsonPost.translates :title, :content, backend: :json, dirty: true, **default_options }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
  end
end if defined?(Sequel) && ENV['DB'] == 'postgres'
