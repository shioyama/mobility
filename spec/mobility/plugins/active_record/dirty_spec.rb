require "spec_helper"

describe "Mobility::Plugins::ActiveRecord::Dirty", orm: :active_record do
  require "mobility/plugins/active_record/dirty"

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
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.extend Mobility
    Article.translates :title, backend: backend_class, dirty: true, cache: false
    Article.translates :content, backend: backend_class, dirty: true, cache: false

    # ensure we include these methods as a module rather than override in class
    changes_applied_method = ::ActiveRecord::VERSION::STRING < '5.1' ? :changes_applied : :changes_internally_applied
    Article.class_eval do
      define_method changes_applied_method do
        super()
      end

      def previous_changes
        super
      end

      def clear_changes_information
        super
      end
    end
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
      end

      aggregate_failures "set same value" do
        article.title = nil
        expect(article.title).to eq(nil)
        expect(article.changed?).to eq(false)
        expect(article.changed).to eq([])
        expect(article.changes).to eq({})
      end

      article.title = "foo"

      aggregate_failures "after change" do
        expect(article.title).to eq("foo")
        expect(article.changed?).to eq(true)
        expect(article.changed).to eq(["title_pt_br"])
        expect(article.changes).to eq({ "title_pt_br" => [nil, "foo"] })
      end
    end

    it "tracks previous changes in one locale" do
      article = Article.create(title: "foo")

      aggregate_failures do
        article.title = "bar"
        expect(article.changed?).to eq(true)

        article.save

        expect(article.changed?).to eq(false)
        expect(article.previous_changes).to include({ "title_en" => ["foo", "bar"]})
      end
    end

    it "tracks previous changes in one locale in before_save hook" do
      article = Article.create(title: "foo")

      article.title = "bar"
      article.save

      article.singleton_class.class_eval do
        before_save do
          @actual_previous_changes = previous_changes
        end
      end

      article.save

      expect(article.instance_variable_get(:@actual_previous_changes)).to include({ "title_en" => ["foo", "bar"]})
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
      article = Article.create(title_en: "English title 1", title_fr: "Titre en Francais 1")

      article.title = "English title 2"
      Mobility.locale = :fr
      article.title = "Titre en Francais 2"

      article.save

      expect(article.previous_changes).to include({
        "title_en" => ["English title 1", "English title 2"],
        "title_fr" => ["Titre en Francais 1", "Titre en Francais 2"]})
    end

    it "tracks forced changes" do
      article = Article.create(title: "foo")

      article.title_will_change!

      aggregate_failures do
        expect(article.changed?).to eq(true)
        expect(article.title_changed?).to eq(true)
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(article.content_changed?).to eq(nil)
        else
          expect(article.content_changed?).to eq(false)
        end
        expect(article.title_change).to eq(["foo", "foo"])
        expect(article.content_change).to eq(nil)
        expect(article.previous_changes).to include({ "title_en" => [nil, "foo"]})

        article.save

        expect(article.changed?).to eq(false)
        expect(article.title_change).to eq(nil)
        expect(article.content_change).to eq(nil)
        expect(article.previous_changes).to include({ "title_en" => ["foo", "foo"]})
      end
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
  end

  describe "suffix methods" do
    it "defines suffix methods on translated attribute" do
      article = Article.new
      article.title = "foo"

      article.save
      aggregate_failures "after save" do
        expect(article.changed?).to eq(false)
        expect(article.title_change).to eq(nil)
        expect(article.title_was).to eq("foo")

        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(article.title_changed?).to eq(nil)
        else
          expect(article.title_previously_changed?).to eq(true)
          expect(article.title_previous_change).to eq([nil, "foo"])
          expect(article.title_changed?).to eq(false)
        end

        # AR-specific suffix methods, added in AR 5.1
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
          expect(article.saved_change_to_title?).to eq(true)
          expect(article.saved_change_to_title).to eq([nil, "foo"])
          expect(article.title_before_last_save).to eq(nil)
          expect(article.title_in_database).to eq("foo")
        end
      end

      article.title = "bar"

      aggregate_failures "changed after save" do
        expect(article.title_changed?).to eq(true)
        expect(article.title_change).to eq(["foo", "bar"])
        expect(article.title_was).to eq("foo")

        article.save
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(article.title_changed?).to eq(nil)
        else
          expect(article.title_previously_changed?).to eq(true)
          expect(article.title_previous_change).to eq(["foo", "bar"])
          expect(article.title_changed?).to eq(false)
        end

        # AR-specific suffix methods
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
          expect(article.saved_change_to_title?).to eq(true)
          expect(article.saved_change_to_title).to eq(["foo", "bar"])
          expect(article.title_before_last_save).to eq("foo")
          expect(article.will_save_change_to_title?).to eq(false)
          expect(article.title_change_to_be_saved).to eq(nil)
          expect(article.title_in_database).to eq("bar")
        end
      end

      aggregate_failures "force change" do
        article.title_will_change!

        aggregate_failures "before save" do
          expect(article.title_changed?).to eq(true)

          # AR-specific suffix methods
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
            expect(article.saved_change_to_title?).to eq(true)
            expect(article.saved_change_to_title).to eq(["foo", "bar"])
            expect(article.title_before_last_save).to eq("foo")
            expect(article.will_save_change_to_title?).to eq(true)
            expect(article.title_change_to_be_saved).to eq(["bar", "bar"])
            expect(article.title_in_database).to eq("bar")
          end
        end

        article.save!

        aggregate_failures "after save" do
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
            expect(article.title_changed?).to eq(nil)
          else
            expect(article.title_changed?).to eq(false)
          end

          # AR-specific suffix methods
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
            expect(article.saved_change_to_title?).to eq(true)
            expect(article.saved_change_to_title).to eq(["bar", "bar"])
            expect(article.title_before_last_save).to eq("bar")
            expect(article.will_save_change_to_title?).to eq(false)
            expect(article.title_change_to_be_saved).to eq(nil)
            expect(article.title_in_database).to eq("bar")
          end
        end
      end
    end

    it "returns changes on attribute for current locale" do
      article = Article.create(title: "foo")

      article.title = "bar"

      aggregate_failures do
        expect(article.title_changed?).to eq(true)
        expect(article.title_change).to eq(["foo", "bar"])
        expect(article.title_was).to eq("foo")

        Mobility.locale = :fr
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(article.title_changed?).to eq(nil)
        else
          expect(article.title_changed?).to eq(false)
        end
        expect(article.title_change).to eq(nil)
        expect(article.title_was).to eq(nil)
      end
    end
  end

  describe "restoring attributes" do
    it "defines restore_<attribute>! for translated attributes" do
      Mobility.locale = :'pt-BR'
      article = Article.create

      article.title = "foo"

      article.restore_title!
      expect(article.title).to eq(nil)
      expect(article.changes).to eq({})
    end

    it "restores attribute when passed to restore_attribute!" do
      article = Article.create

      article.title = "foo"
      article.send :restore_attribute!, :title

      expect(article.title).to eq(nil)
    end

    it "handles translated attributes when passed to restore_attributes" do
      article = Article.create(title: "foo")

      expect(article.title).to eq("foo")

      article.title = "bar"
      expect(article.title).to eq("bar")
      article.restore_attributes([:title])
      expect(article.title).to eq("foo")
    end
  end

  describe "resetting original values hash on actions" do
    shared_examples_for "resets on model action" do |action|
      it "resets changes when model on #{action}" do
        article = Article.create

        aggregate_failures do
          article.title = "foo"
          expect(article.changes).to eq({ "title_en" => [nil, "foo"] })

          article.send(action)

          # bypass the dirty module and set the variable directly
          article.mobility_backend_for("title").instance_variable_set(:@values, { :en => "bar" })

          expect(article.title).to eq("bar")
          expect(article.changes).to eq({})

          article.title = nil
          expect(article.changes).to eq({ "title_en" => ["bar", nil]})
        end
      end
    end

    it_behaves_like "resets on model action", :save
    it_behaves_like "resets on model action", :reload
  end

  if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
    describe "#saved_changes" do
      it "includes translated attributes" do
        article = Article.create

        article.title = "foo en"
        Mobility.with_locale(:ja) { article.title = "foo ja" }
        article.save

        aggregate_failures do
          saved_changes = article.saved_changes
          expect(saved_changes).to include("title_en", "title_ja")
          expect(saved_changes["title_en"]).to eq([nil, "foo en"])
          expect(saved_changes["title_ja"]).to eq([nil, "foo ja"])
        end
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
