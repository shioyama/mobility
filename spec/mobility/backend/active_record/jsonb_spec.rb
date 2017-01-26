require "spec_helper"

describe Mobility::Backend::ActiveRecord::Jsonb, orm: :active_record, db: :postgres do
  extend Helpers::ActiveRecord

  let(:backend) { post.title_translations }

  before do
    stub_const 'JsonbPost', Class.new(ActiveRecord::Base)
    JsonbPost.include Mobility
    JsonbPost.translates :title, :content, backend: :jsonb, cache: false
  end
  let(:post) { JsonbPost.new }

  include_accessor_examples 'JsonbPost'
  include_serialization_examples 'JsonbPost'
  include_querying_examples 'JsonbPost'

  it "raises error if format is present and not :json" do
    expect {
      JsonbPost.translates :foo, backend: :jsonb, format: :yaml
    }.to raise_error(ArgumentError, "Format must be JSON for Jsonb backend.")
  end

  it "sets options[:format] to json" do
    expect(backend.options[:format]).to eq(:json)
  end
end
