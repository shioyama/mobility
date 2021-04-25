require "spec_helper"

return unless defined?(ActiveRecord)

require "mobility/plugins/active_record/query"

# @note Although this plugin should probably really be tested against an
#   abstract backend with +build_node+ and +apply_scope+ defined and tested,
#   doing so would be quite involved, so instead this spec tests against a
#   complex combination of existing backends, which is less precise but should
#   be sufficient at this stage.
#
describe Mobility::Plugins::ActiveRecord::Query, orm: :active_record, type: :plugin do
  plugins :active_record, :writer, :query
  plugin_setup

  describe "query scope" do
    let(:model_class) do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      Article.include translations
      Article
    end

    context "default query scope" do
      it "defines query scope" do
        expect(model_class.i18n).to eq(described_class.build_query(model_class, Mobility.locale))
      end
    end

    context "custom query scope" do
      plugins do
        query :foo
        active_record
      end

      it "defines query scope" do
        expect(model_class.foo).to eq(described_class.build_query(model_class, Mobility.locale))
        expect { model_class.i18n }.to raise_error(NoMethodError)
      end
    end
  end

  describe "query methods" do
    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
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
      stub_const 'Article', Class.new(ActiveRecord::Base)
      translates Article, :title, backend: :table
      article = Article.create(title: "foo")
      expect(Article.i18n.first).to eq(article)
    end
  end

  describe "virtual row handling" do
    before do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      translates Article, :title, backend: :table
      translates Article, :subtitle, backend: :table
      translates Article, :content, type: :text, backend: :key_value
      translates Article, :author, type: :string, backend: :key_value

      Article.has_many :comments

      stub_const 'Comment', Class.new(ActiveRecord::Base)
      translates Comment, :author, backend: :column
      Comment.belongs_to :article
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

      context "multiple locales" do
        it "applies locale argument to node" do
          article1 = Article.create(author: "foo")
          Mobility.with_locale(:ja) { article1.author = "ほげ"; article1.save }
          article2 = Article.create(author: "bar")
          Mobility.with_locale(:ja) { article2.author = "ふが"; article2.save }

          expect(Article.i18n { author(:en).eq("foo").and(author(:ja).eq("ほげ")) }).to eq([article1])
          expect(Article.i18n { author(:en).eq("foo").and(author(:ja).eq("ふが")) }).to eq([])
          expect(Article.i18n { author(:en).eq("bar").and(author(:ja).eq("ふが")) }).to eq([article2])
          expect(Article.i18n { author(:en).eq("bar").and(author(:ja).eq("ほげ")) }).to eq([])

          expect(Article.i18n { author(:en).eq("foo").or(author(:ja).eq("ほげ")) }).to eq([article1])
          expect(Article.i18n { author(:en).eq("foo").or(author(:ja).eq("ふが")) }).to match_array([article1, article2])
          expect(Article.i18n { author(:en).eq("bar").or(author(:ja).eq("ふが")) }).to eq([article2])
          expect(Article.i18n { author(:en).eq("bar").or(author(:ja).eq("ほげ")) }).to match_array([article1, article2])
        end

        it "raises InvalidLocale exception if locale is invalid" do
          expect { Article.i18n { author([]).eq("foo") } }.to raise_error(Mobility::InvalidLocale)
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

  describe ".build_query" do
    it "builds VirtualRow" do
      stub_const 'Article', Class.new(ActiveRecord::Base)
      translates Article, :title, backend: :table

      article_en = Article.create(title: "foo")
      article_ja = Mobility.with_locale(:ja) { Article.create(title: "ほげ") }

      expect(described_class.build_query(Article) do
        title.eq('foo')
      end).to eq([article_en])

      expect(described_class.build_query(Article) do
        title.eq('ほげ')
      end).to eq([])

      expect(described_class.build_query(Article, :ja) do
        title.eq('foo')
      end).to eq([])

      expect(described_class.build_query(Article, :ja) do
        title.eq('ほげ')
      end).to eq([article_ja])
    end
  end

  describe "regression for #513" do
    plugins :active_record, :query
    before do
      m = ActiveRecord::Migration.new
      m.verbose = false

      m.create_table :cars
      stub_const('Car', Class.new(ActiveRecord::Base) do
        has_many :parking_lots
        has_many :car_parts
      end)
      translates Car, backend: :column

      m.create_table(:parking_lots) { |t| t.integer :car_id }
      stub_const('ParkingLot', Class.new(ActiveRecord::Base) do
        belongs_to :car
      end)

      m.create_table(:car_parts) { |t| t.integer :car_id }
      stub_const('CarPart', Class.new(ActiveRecord::Base) do
        belongs_to :car
      end)
      translates CarPart, backend: :column
    end
    after do
      m = ActiveRecord::Migration.new
      m.verbose = false
      m.drop_table :cars
      m.drop_table :parking_lots
      m.drop_table :car_parts
    end

    it "does not raise NameError" do
      query = ParkingLot.includes(car: :car_parts).references(:car).merge(Car.i18n)
      expect { query.first }.not_to raise_error
      expect { query.order(:car_id) }.not_to raise_error
    end
  end
end
