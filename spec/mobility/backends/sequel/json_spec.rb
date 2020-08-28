require "spec_helper"

return unless defined?(Sequel) && defined?(PG)

describe "Mobility::Backends::Sequel::Json", orm: :sequel, db: :postgres, type: :backend do
  require "mobility/backends/sequel/json"

  column_options = { column_prefix: 'my_', column_suffix: '_i18n' }
  column_affix = "#{column_options[:column_prefix]}%s#{column_options[:column_suffix]}"

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonPost.new }

  before do
    stub_const 'JsonPost', Class.new(Sequel::Model)
    JsonPost.dataset = DB[:json_posts]
  end

  let(:backend) { post.mobility_backends[:title] }
  let(:post) { JsonPost.new }

  context "with no plugins" do
    include_backend_examples described_class, 'JsonPost'
  end

  context "with basic plugins" do
    plugins :sequel, :reader, :writer

    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
    include_dup_examples 'JsonPost'
  end

  context "with query plugin" do
    plugins :sequel, :reader, :writer, :query

    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_querying_examples 'JsonPost'
  end

  context "with dirty plugin" do
    plugins :sequel, :reader, :writer, :dirty

    before { translates JsonPost, :title, :content, backend: :json, **column_options }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost', column_affix: column_affix
  end
end
