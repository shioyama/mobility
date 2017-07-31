require "spec_helper"

describe Mobility::Backends::ActiveRecord::Hstore, orm: :active_record, db: :postgres do
  extend Helpers::ActiveRecord

  context "with no option modules applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      include Mobility
      self.table_name = 'hstore_posts'
    end)
  end

  context "with standard option modules applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before do
      stub_const 'HstorePost', Class.new(ActiveRecord::Base)
      HstorePost.include Mobility
      HstorePost.translates :title, :content, backend: :hstore, cache: false
    end
    let(:post) { HstorePost.new }

    include_accessor_examples 'HstorePost'
    include_serialization_examples 'HstorePost'
    include_querying_examples 'HstorePost'
    include_validation_examples 'HstorePost'

    describe "non-text values" do
      it "converts non-string types to strings when saving" do
        post = HstorePost.new
        backend = post.mobility_backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post.read_attribute(:title)).to match_hash({ en: "{:foo=>:bar}" })
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
