require "spec_helper"

describe Mobility::Backend::ActiveRecord::Hstore, orm: :active_record, db: :postgres do
  extend Helpers::ActiveRecord

  let(:backend) { post.title_translations }

  before do
    stub_const 'HstorePost', Class.new(ActiveRecord::Base)
    HstorePost.include Mobility
    HstorePost.translates :title, :content, backend: :hstore, cache: false
  end
  let(:post) { HstorePost.new }

  include_accessor_examples 'HstorePost'
  include_serialization_examples 'HstorePost'
#  include_querying_examples 'HstorePost'
end
