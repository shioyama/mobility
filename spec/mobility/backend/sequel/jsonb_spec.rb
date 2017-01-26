require "spec_helper"

describe Mobility::Backend::Sequel::Jsonb, orm: :sequel, db: :postgres do
  extend Helpers::Sequel

  let(:backend) { post.title_translations }

  before do
    stub_const 'JsonbPost', Class.new(Sequel::Model)
    JsonbPost.dataset = DB[:jsonb_posts]
    JsonbPost.include Mobility
    JsonbPost.translates :title, :content, backend: :jsonb, cache: false
  end
  let(:post) { JsonbPost.new }

  include_accessor_examples 'JsonbPost'
  include_serialization_examples 'JsonbPost'
  include_querying_examples 'JsonbPost'
end
