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
end
