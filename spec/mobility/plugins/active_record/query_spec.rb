require "spec_helper"

# @note Although this plugin should probably really be tested against an
#   abstract backend with +build_node+ and +apply_scope+ defined and tested,
#   doing so would be quite involved, so instead this spec tests against a
#   complex combination of existing backends, which is less precise but should
#   be sufficient at this stage.
#
describe "Mobility::Plugins::ActiveRecord::Query", orm: :active_record do
  require "mobility/plugins/active_record/query"

  describe "query methods" do
    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.class_eval do
        extend Mobility
        translates :title, backend: :table
      end
    end

    it "does not modify original opts hash" do
      options = { title: "foo", locale: :en }
      options_ = options.dup
      Article.i18n.where(options_)
      expect(options_).to eq(options)
    end
  end

  describe "query method" do
    # NOTE: __mobility_query_scope__ is a public method for convenience, but is
    # intended for internal use. For application code, use i18n or whatever you
    # define in Mobility.query_method instead.
    it "creates a __mobility_query_scope__ method" do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.class_eval do
        extend Mobility
        translates :title, backend: :table
      end
      article = Article.create(title: "foo")
      expect(Article.__mobility_query_scope__.first).to eq(article)
    end
  end

  describe "virtual row handling" do
    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.class_eval do
        extend Mobility
        translates :title, backend: :table
        translates :subtitle, backend: :table
        translates :content, type: :text, backend: :key_value
        translates :author, type: :string, backend: :key_value
        has_many :comments
      end

      stub_const 'Comment', Class.new(ActiveRecord::Base)
      Comment.class_eval do
        extend Mobility
        belongs_to :article
        translates :author, backend: :column
      end
    end

    # TODO: Test more thoroughly
    context "single-block querying" do
      context "multiple backends" do
        it "does not join translations table when backend node not included in predicate" do
          Article.i18n { title; content.eq("bazcontent").or(author.eq("foobarauthor")) }.tap do |relation|
            expect(relation.to_sql).not_to match /article_translations/
          end
        end
      end
    end

    # TODO: Test more thoroughly
    context "multiple-block querying" do
      it "returns records matching predicate across models" do
        article1 = Article.create(author: "foo")
        article2 = Article.create(author: "foo")
        comment1 = article1.comments.create(author: "foo")
        comment2 = article2.comments.create(author: "baz")

        expect(Article.i18n { |a| a.author.eq("foo") }).to match_array([article1, article2])
        expect(Comment.i18n { |c| c.author.eq("foo") }).to eq([comment1])

        expect(Article.joins(:comments).i18n { |a| Comment.i18n { |c| a.author.eq(c.author) } }).to eq([article1])
      end
    end
  end
end if defined?(ActiveRecord)
