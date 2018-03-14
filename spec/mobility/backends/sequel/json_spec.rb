require "spec_helper"

describe "Mobility::Backends::Sequel::Json", orm: :sequel, db: :postgres do
  require "mobility/backends/sequel/json"
  extend Helpers::Sequel
  before do
    stub_const 'JsonPost', Class.new(Sequel::Model)
    JsonPost.dataset = DB[:json_posts]
    JsonPost.extend Mobility
  end

  context "with no plugins applied" do
    include_backend_examples described_class, (Class.new(Sequel::Model(:json_posts)) do
      extend Mobility
    end)
  end

  context "with standard plugins applied" do
    let(:backend) { post.mobility.backend_for("title") }

    before { JsonPost.translates :title, :content, backend: :json, cache: false, presence: false }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost'
    include_querying_examples 'JsonPost'
    include_dup_examples 'JsonPost'
  end

  context "with dirty plugin applied" do
    let(:backend) { post.mobility.backend_for("title") }

    before { JsonPost.translates :title, :content, backend: :json, cache: false, presence: false, dirty: true }
    let(:post) { JsonPost.new }

    include_accessor_examples 'JsonPost'
    include_serialization_examples 'JsonPost'
  end
end if Mobility::Loaded::Sequel && ENV['DB'] == 'postgres'
