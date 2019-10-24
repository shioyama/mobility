require "spec_helper"

describe "Mobility::Plugins::ActiveModel::Dirty", orm: :active_record do
  require "mobility/plugins/active_model/dirty"

  let(:backend_class) do
    Class.new(Mobility::Backends::Null) do
      def read(locale, **options)
        values[locale]
      end

      def write(locale, value, **options)
        values[locale] = value
      end

      private

      def values
        @values ||= {}
      end
    end
  end

  before do
    # define class with both translated and untranslated attributes
    stub_const 'Article', Class.new {
      include ActiveModel::Dirty

      define_attribute_methods :published
      attr_reader :published

      def initialize
        @published = nil
      end

      def published=(published)
        published_will_change! unless published == @published
        @published = published
      end

      def save
        changes_applied
      end
    }
    Article.extend Mobility
    Article.translates :title, backend: backend_class, dirty: true, cache: false
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      Mobility.locale = :'pt-BR'
      article = Article.new

      aggregate_failures "before change" do
        expect(article.title).to eq(nil)
        expect(article.changed?).to eq(false)
        expect(article.changed).to eq([])
        expect(article.changes).to eq({})
        expect(article.changed_attributes).to eq({})
      end

      aggregate_failures "set same value" do
        article.title = nil
        expect(article.title).to eq(nil)
        expect(article.changed?).to eq(false)
        expect(article.changed).to eq([])
        expect(article.changes).to eq({})
        expect(article.changed_attributes).to eq({})
      end

      article.title = "foo"
      article.published = false

      aggregate_failures "after change" do
        expect(article.title).to eq("foo")
        expect(article.changed?).to eq(true)
        expect(article.changed).to match_array(['title_pt_br', 'published'])
        expect(article.changes).to eq({ 'title_pt_br' => [nil, 'foo'], 'published' => [nil, false] })
        expect(article.changed_attributes).to eq({ 'title_pt_br' => nil, 'published' => nil })
      end
    end

    it "tracks previous changes in one locale" do
      article = Article.new
      article.title = "foo"
      article.published = false
      article.save

      aggregate_failures do
        article.title = 'bar'
        expect(article.changed?).to eq(true)

        article.title = 'foo'
        expect(article.changed?).to eq(false)

        # ensure still works with untranslated attributes
        article.published = true
        expect(article.changed?).to eq(true)

        article.title = 'bar'
        article.save

        expect(article.changed?).to eq(false)
        expect(article.previous_changes).to eq({ 'title_en' => ['foo', 'bar'], 'published' => [false, true]})
      end
    end

    it "tracks changes in multiple locales" do
      article = Article.new

      expect(article.title).to eq(nil)

      aggregate_failures "change in English locale" do
        article.title = "English title"

        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_en"])
        expect(article.changes).to eq({ "title_en" => [nil, "English title"] })
      end

      aggregate_failures "change in French locale" do
        Mobility.locale = :fr

        article.title = "Titre en Francais"
        expect(article.changed?).to eq(true)
        expect(article.changed).to match_array(["title_en", "title_fr"])
        expect(article.changes).to eq({ "title_en" => [nil, "English title"], "title_fr" => [nil, "Titre en Francais"] })
      end
    end

    it "tracks previous changes in multiple locales" do
      article = Article.new
      article.title_en = "English title 1"
      article.title_fr = "Titre en Francais 1"
      article.save

      article.title = "English title 2"
      Mobility.locale = :fr
      article.title = "Titre en Francais 2"

      article.save

      expect(article.previous_changes).to eq({"title_en" => ["English title 1", "English title 2"],
                                              "title_fr" => ["Titre en Francais 1", "Titre en Francais 2"]})
    end

    it "resets changes when locale is set to original value" do
      article = Article.new

      expect(article.changed?).to eq(false)

      aggregate_failures "after change" do
        article.title = "foo"
        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_en"])
        expect(article.changes).to eq({ "title_en" => [nil, "foo"] })
      end

      aggregate_failures "after setting attribute back to original value" do
        article.title = nil
        expect(article.changed?).to eq(false)
        expect(article.changed).to eq([])
        expect(article.changes).to eq({})
      end

      aggregate_failures "changing value in different locale" do
        Mobility.with_locale(:fr) { article.title = "Titre en Francais" }

        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_fr"])
        expect(article.changes).to eq({ "title_fr" => [nil, "Titre en Francais"] })
      end
    end

    it 'clears changes information on translated attributes' do
      article = Article.new
      expect(article.changed?).to eq(false)

      article.title = 'foo'
      expect(article.changed?).to eq(true)

      article.send(:clear_changes_information) # private in earlier versions of Rails
      expect(article.changed?).to eq(false)
    end

    # regression to ensure this works as usual
    it 'clears changes information on translated attributes' do
      article = Article.new
      expect(article.changed?).to eq(false)

      article.published = true
      expect(article.changed?).to eq(true)

      article.send(:clear_changes_information) # private in earlier versions of Rails
      expect(article.changed?).to eq(false)
    end
  end

  describe "suffix methods" do
    it "defines suffix methods on translated attribute", rails_version_geq: '5.0' do
      article = Article.new
      article.title = "foo"
      article.save

      article.title = "bar"

      aggregate_failures do
        expect(article.title_changed?).to eq(true)
        #expect(article.title_changed?(from: 'foo', to: 'bar')).to eq(true)
        #expect(article.title_changed?(from: 'foo', to: 'baz')).to eq(false)
        expect(article.title_change).to eq(["foo", "bar"])
        expect(article.title_was).to eq("foo")

        expect(article.attribute_changed?(:title_en)).to eq(true)
        expect(article.attribute_changed?('title_en')).to eq(true) # ensure string values are handled
        expect(article.attribute_changed?(:title)).to eq(false)    # only attribute name + locale is tracked
        expect(article.attribute_changed?(:title_en, from: 'foo', to: 'bar')).to eq(true)
        expect(article.attribute_changed?(:title_en, from: 'foo', to: 'baz')).to eq(false)
        expect(article.attribute_was(:title_en)).to eq('foo')

        article.save
        expect(article.title_changed?).to eq(false)
        expect(article.attribute_changed?(:title_en)).to eq(false)

        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] >= '5.0'
          expect(article.title_previously_changed?).to eq(true)
          expect(article.title_previous_change).to eq(["foo", "bar"])
          expect(article.title_changed?).to eq(false)

          expect(article.attribute_previously_changed?(:title_en)).to eq(true)
          expect(article.attribute_changed?(:title_en)).to eq(false)

          # Uncomment when Rails 6.1 is released
          # if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] >= '6.1'
          #   expect(article.title_previously_was).to eq('foo')
          #   expect(article.attribute_previously_was(:title)).to eq('foo')
          # end
        end

        article.title_will_change!
        expect(article.title_changed?).to eq(true)

        article.send(:changes_applied) # private method in earlier versions of Rails
        expect(article.title_changed?).to eq(false)
      end
    end

    # This is a regression spec to ensure we don't change the scope of
    # ActiveModel handler methods.
    it 'does not change private status of attribute handler methods', rails_version_geq: '5.0' do
      article = Article.new
      expect(article.respond_to?(:attribute_change)).to eq(false)
      expect(article.respond_to?(:attribute_change, true)).to eq(true)
      expect(article.respond_to?(:attribute_previous_change)).to eq(false)
      expect(article.respond_to?(:attribute_previous_change, true)).to eq(true)
      expect(article.respond_to?(:attribute_will_change!)).to eq(false)
      expect(article.respond_to?(:attribute_will_change!, true)).to eq(true)
      expect(article.respond_to?(:restore_attribute!)).to eq(false)
      expect(article.respond_to?(:restore_attribute!, true)).to eq(true)
    end

    %w[changes_applied clear_changes_information].each do |method_name|
      it "does not change private status of #{method_name}" do
        klass = Class.new { include ::ActiveModel::Dirty }
        dirty = klass.new
        article = Article.new

        expect(article.respond_to?(method_name)).to eq(dirty.respond_to?(method_name))
        expect(article.respond_to?(method_name, true)).to eq(dirty.respond_to?(method_name, true))
      end
    end

    it "returns changes on attribute for current locale", rails_version_geq: '5.0' do
      article = Article.new
      article.title = "foo"
      article.save

      article.title = "bar"

      aggregate_failures do
        expect(article.title_changed?).to eq(true)
        expect(article.title_change).to eq(["foo", "bar"])
        expect(article.title_was).to eq("foo")

        Mobility.locale = :fr
        expect(article.title_changed?).to eq(false)
        expect(article.title_change).to eq(nil)
        expect(article.title_was).to eq(nil)

        expect(article.attribute_changed?(:title_en)).to eq(true)
        expect(article.attribute_changed?(:title_fr)).to eq(false)
        expect(article.attribute_was(:title_en)).to eq('foo')
        expect(article.attribute_was(:title_ja)).to eq(nil)
      end
    end
  end

  describe "restoring attributes" do
    it "defines restore_<attribute>! for translated attributes" do
      Mobility.locale = :'pt-BR'
      article = Article.new
      article.save

      article.title = "foo"

      article.restore_title!
      expect(article.title).to eq(nil)
      expect(article.changes).to eq({})
    end

    it "restores attribute when passed to restore_attribute!" do
      article = Article.new
      article.save

      article.title = "foo"
      article.send :restore_attribute!, :title

      expect(article.title).to eq(nil)
    end

    it "handles translated attributes when passed to restore_attributes" do
      article = Article.new
      article.title = "foo"
      article.save

      expect(article.title).to eq("foo")

      article.title = "bar"
      expect(article.title).to eq("bar")
      article.restore_attributes([:title])
      expect(article.title).to eq("foo")
    end
  end

  describe "fallbacks compatiblity" do
    before do
      stub_const 'ArticleWithFallbacks', Class.new
      ArticleWithFallbacks.class_eval do
        include ActiveModel::Dirty
        extend Mobility
      end
      ArticleWithFallbacks.translates :title, backend: backend_class, dirty: true, cache: false, fallbacks: { en: 'ja' }
    end

    it "does not compare with fallback value" do
      article = ArticleWithFallbacks.new

      aggregate_failures "before change" do
        expect(article.title).to eq(nil)
        expect(article.changed?).to eq(false)
        expect(article.changed).to eq([])
        expect(article.changes).to eq({})
      end

      aggregate_failures "set fallback locale value" do
        Mobility.with_locale(:ja) { article.title = "あああ" }
        expect(article.title).to eq("あああ")
        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_ja"])
        expect(article.changes).to eq({ "title_ja" => [nil, "あああ"]})
        Mobility.with_locale(:ja) { expect(article.title).to eq("あああ") }
      end

      aggregate_failures "set value in current locale to same value" do
        article.title = nil
        expect(article.title).to eq("あああ")
        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_ja"])
        expect(article.changes).to eq({ "title_ja" => [nil, "あああ"]})
      end

      aggregate_failures "set value in fallback locale to different value" do
        Mobility.with_locale(:ja) { article.title = "ばばば" }
        expect(article.title).to eq("ばばば")
        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_ja"])
        expect(article.changes).to eq({ "title_ja" => [nil, "ばばば"]})
      end

      aggregate_failures "set value in current locale to different value" do
        article.title = "Title"
        expect(article.title).to eq("Title")
        expect(article.changed?).to eq(true)
        expect(article.changed).to match_array(["title_ja", "title_en"])
        expect(article.changes).to eq({ "title_ja" => [nil, "ばばば"], "title_en" => [nil, "Title"]})
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
