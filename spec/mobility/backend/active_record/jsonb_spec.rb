require "spec_helper"

describe Mobility::Backend::ActiveRecord::Jsonb, orm: :active_record, db: :postgres do
  extend Helpers::ActiveRecord

  context "with no option modules applied" do
    include_backend_examples described_class, (Class.new(ActiveRecord::Base) do
      include Mobility
      self.table_name = 'jsonb_posts'
    end)
  end

  context "with standard option modules applied" do
    let(:backend) { post.mobility_backend_for("title") }

    before do
      stub_const 'JsonbPost', Class.new(ActiveRecord::Base)
      JsonbPost.include Mobility
      JsonbPost.translates :title, :content, backend: :jsonb, cache: false
    end
    let(:post) { JsonbPost.new }

    include_accessor_examples 'JsonbPost'
    include_serialization_examples 'JsonbPost'
    include_querying_examples 'JsonbPost'
    include_validation_examples 'JsonbPost'

    describe "non-text values" do
      it "stores non-string types as-is when saving", rails_version_geq: '5.0' do
        post = JsonbPost.new
        backend = post.mobility_backend_for("title")
        backend.write(:en, { foo: :bar } )
        post.save
        expect(post.read_attribute(:title)).to eq({ "en" => { "foo" => "bar" }})
      end

      it "stores integer values" do
        post.title = 1
        expect(post.title).to eq(1)
        post.save

        post = JsonbPost.first
        expect(post.title).to eq(1)
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
