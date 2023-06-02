require "spec_helper"

return unless defined?(Sequel)

require "mobility/plugins/sequel/query"

describe Mobility::Plugins::Sequel::Query, orm: :sequel, type: :plugin do
  plugins :sequel, :reader, :writer, :query, :cache
  plugin_setup

  describe "query_scope" do
    let(:model_class) do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      Article.include translations
      Article
    end

    context "default query scope" do
      it "defines query scope" do
        expect(model_class.i18n.sql).to eq(described_class.build_query(model_class, Mobility.locale).sql)
      end
    end

    context "custom query scope" do
      plugins do
        query :foo
        sequel
      end

      it "defines query scope" do
        expect(model_class.foo.sql).to eq(described_class.build_query(model_class, Mobility.locale).sql)
        expect { model_class.i18n }.to raise_error(NoMethodError)
      end
    end
  end

  describe "query methods" do
    before do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      translates Article, :title, backend: :table
    end

    it "does not modify original opts hash" do
      options = { title: "foo", locale: :en }
      options_ = options.dup
      Article.i18n.where(options_)
      expect(options_).to eq(options)
    end
  end

  describe "query method" do
    it "creates a query method method" do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      translates Article, :title, backend: :table
      article = Article.create(title: "foo")
      expect(Article.i18n.first).to eq(article)
    end
  end

  describe "virtual row handling" do
    before do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      translates Article, :title, backend: :table
      translates Article, :subtitle, backend: :table
      translates Article, :content, type: :text, backend: :key_value
      translates Article, :author, type: :string, backend: :key_value

      Article.one_to_many :comments

      stub_const 'Comment', Class.new(Sequel::Model)
      Comment.dataset = DB[:comments]
      translates Comment, :author, backend: :column
      Comment.many_to_one :article
    end

    # TODO: Test more thoroughly
    context "single-block querying" do
      context "multiple backends" do
        # TODO: Make this work. Requires changes to Table + KeyValue backends
        # to use a custom op type like we do in the ActiveRecord backends with
        # Mobility::Plugins::Arel::Attribute which tracks table.
        pending "does not join translations table when backend node not included in predicate" do
          Article.i18n { title; (content =~ "bazcontent") | (author =~ "foobarauthor") }.tap do |relation|
            expect(relation.sql).not_to match /article_translations/
          end
        end
      end

      context "multiple locales" do
        it "applies locale argument to node" do
          article1 = Article.create(author: "foo")
          Mobility.with_locale(:ja) { article1.author = "ほげ"; article1.save }
          article2 = Article.create(author: "bar")
          Mobility.with_locale(:ja) { article2.author = "ふが"; article2.save }

          expect(Article.i18n { (author(:en) =~ "foo") & (author(:ja) =~ "ほげ") }.select_all(:articles).all).to match_array([article1])
          expect(Article.i18n { (author(:en) =~ "foo") & (author(:ja) =~ "ふが") }.select_all(:articles).all).to eq([])
          expect(Article.i18n { (author(:en) =~ "bar") & (author(:ja) =~ "ふが") }.select_all(:articles).all).to match_array([article2])
          expect(Article.i18n { (author(:en) =~ "bar") & (author(:ja) =~ "ほげ") }.select_all(:articles).all).to eq([])

          expect(Article.i18n { (author(:en) =~ "foo") | (author(:ja) =~ "ほげ") }.select_all(:articles).all).to match_array([article1])
          expect(Article.i18n { (author(:en) =~ "foo") | (author(:ja) =~ "ふが") }.select_all(:articles).all).to match_array([article1, article2])
          expect(Article.i18n { (author(:en) =~ "bar") | (author(:ja) =~ "ふが") }.select_all(:articles).all).to match_array([article2])
          expect(Article.i18n { (author(:en) =~ "bar") | (author(:ja) =~ "ほげ") }.select_all(:articles).all).to match_array([article1, article2])
        end

        it "raises InvalidLocale exception if locale is invalid" do
          expect { Article.i18n { author([]) =~ "foo" } }.to raise_error(Mobility::InvalidLocale)
        end
      end
    end

    # TODO: Test more thoroughly
    context "multiple-block querying" do
      it "returns records matching predicate across models" do
        article1 = Article.create(author: "foo")
        article2 = Article.create(author: "foo")
        comment1 = article1.add_comment(author: "foo")
        comment2 = article2.add_comment(author: "baz")

        expect(Article.i18n { |a| a.author =~ "foo" }.select_all(:articles).all).to match_array([article1, article2])
        expect(Comment.i18n { |c| c.author =~ "foo" }.select_all(:comments).all).to eq([comment1])

        # This doens't work because dataset is not defined on join. Not digging into it, but could possibly be made to work.
        #expect(Article.join(:comments).i18n { |a| Comment.i18n { |c| a.author.eq(c.author) } }.select_all(:articles).all).to eq([article1])
      end
    end
  end

  describe ".build_query" do
    it "builds VirtualRow" do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]
      translates Article, :title, backend: :table

      article_en = Article.create(title: "foo")
      article_ja = Mobility.with_locale(:ja) { Article.create(title: "ほげ") }

      expect(described_class.build_query(Article) do
        title =~ 'foo'
      end.select_all(:articles).all).to eq([article_en])

      expect(described_class.build_query(Article) do
        title =~ 'ほげ'
      end.select_all(:articles).all).to eq([])

      expect(described_class.build_query(Article, :ja) do
        title =~ 'foo'
      end.select_all(:articles).all).to eq([])

      expect(described_class.build_query(Article, :ja) do
        title =~ 'ほげ'
      end.select_all(:articles).all).to eq([article_ja])
    end
  end

  describe "regression for #564 (Sequel version)" do
    it "works if translates is called multiple times" do
      stub_const 'Article', Class.new(Sequel::Model)
      Article.dataset = DB[:articles]

      2.times { translates Article, :title, backend: :table }

      article = Article.create(title: "Title")

      expect(Article.i18n.where(title: "Title").select_all(:articles).all).to eq([article])
    end
  end
end
