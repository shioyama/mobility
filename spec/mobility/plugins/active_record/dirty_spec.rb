require "spec_helper"

describe "Mobility::Plugins::ActiveRecord::Dirty", orm: :active_record do
  require "mobility/plugins/active_record/dirty"

  include Helpers::Plugins
  plugin_setup "title", dirty: true

  let(:model_class) do
    stub_const 'Article', Class.new(ActiveRecord::Base)
    Article.include attributes
    Article.include attributes_class.new("content", backend: backend_listener(double(:backend)), dirty: true)

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

    Article
  end

  let(:backend_class) do
    Class.new do
      include Mobility::Backend
      def read(locale, **)
        [locale, values[locale]]
      end

      def write(locale, value, **)
        [locale, values[locale] = value]
      end

      private
      def values; @values ||= {}; end
    end
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      Mobility.locale = :'pt-BR'

      aggregate_failures "before change" do
        expect(instance.title).to eq(nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      aggregate_failures "set same value" do
        instance.title = nil
        expect(instance.title).to eq(nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      instance.title = "foo"

      aggregate_failures "after change" do
        expect(instance.title).to eq("foo")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_pt_br"])
        expect(instance.changes).to eq({ "title_pt_br" => [nil, "foo"] })
      end
    end

    it "tracks previous changes in one locale" do
      instance = model_class.create(title: "foo")

      aggregate_failures do
        instance.title = "bar"
        expect(instance.changed?).to eq(true)

        instance.save

        expect(instance.changed?).to eq(false)
        expect(instance.previous_changes).to include({ "title_en" => ["foo", "bar"]})
      end
    end

    it "tracks previous changes in one locale in before_save hook" do
      instance = model_class.create(title: "foo")

      instance.title = "bar"
      instance.save

      instance.singleton_class.class_eval do
        before_save do
          @actual_previous_changes = previous_changes
        end
      end

      instance.save

      expect(instance.instance_variable_get(:@actual_previous_changes)).to include({ "title_en" => ["foo", "bar"]})
    end

    it "tracks changes in multiple locales" do
      expect(instance.title).to eq(nil)

      aggregate_failures "change in English locale" do
        instance.title = "English title"

        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_en"])
        expect(instance.changes).to eq({ "title_en" => [nil, "English title"] })
      end

      aggregate_failures "change in French locale" do
        Mobility.locale = :fr

        instance.title = "Titre en Francais"
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to match_array(["title_en", "title_fr"])
        expect(instance.changes).to eq({ "title_en" => [nil, "English title"], "title_fr" => [nil, "Titre en Francais"] })
      end
    end

    it "tracks previous changes in multiple locales" do
      instance = model_class.create(title_en: "English title 1", title_fr: "Titre en Francais 1")

      instance.title = "English title 2"
      Mobility.locale = :fr
      instance.title = "Titre en Francais 2"

      instance.save

      expect(instance.previous_changes).to include({
        "title_en" => ["English title 1", "English title 2"],
        "title_fr" => ["Titre en Francais 1", "Titre en Francais 2"]})
    end

    it "tracks forced changes" do
      instance = model_class.create(title: "foo")

      instance.title_will_change!

      aggregate_failures do
        expect(instance.changed?).to eq(true)
        expect(instance.title_changed?).to eq(true)
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(instance.content_changed?).to eq(nil)
        else
          expect(instance.content_changed?).to eq(false)
        end
        expect(instance.title_change).to eq(["foo", "foo"])
        expect(instance.content_change).to eq(nil)
        expect(instance.previous_changes).to include({ "title_en" => [nil, "foo"]})

        instance.save

        expect(instance.changed?).to eq(false)
        expect(instance.title_change).to eq(nil)
        expect(instance.content_change).to eq(nil)
        expect(instance.previous_changes).to include({ "title_en" => ["foo", "foo"]})
      end
    end

    it "resets changes when locale is set to original value" do
      expect(instance.changed?).to eq(false)

      aggregate_failures "after change" do
        instance.title = "foo"
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_en"])
        expect(instance.changes).to eq({ "title_en" => [nil, "foo"] })
      end

      aggregate_failures "after setting attribute back to original value" do
        instance.title = nil
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      aggregate_failures "changing value in different locale" do
        Mobility.with_locale(:fr) { instance.title = "Titre en Francais" }

        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_fr"])
        expect(instance.changes).to eq({ "title_fr" => [nil, "Titre en Francais"] })
      end
    end
  end

  describe "suffix methods" do
    it "defines suffix methods on translated attribute" do
      instance.title = "foo"

      instance.save
      aggregate_failures "after save" do
        expect(instance.changed?).to eq(false)
        expect(instance.title_change).to eq(nil)
        expect(instance.title_was).to eq("foo")

        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(instance.title_changed?).to eq(nil)
        else
          expect(instance.title_previously_changed?).to eq(true)
          expect(instance.title_previous_change).to eq([nil, "foo"])
          expect(instance.title_changed?).to eq(false)
        end

        # AR-specific suffix methods, added in AR 5.1
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
          expect(instance.saved_change_to_title?).to eq(true)
          expect(instance.saved_change_to_title).to eq([nil, "foo"])
          expect(instance.title_before_last_save).to eq(nil)
          expect(instance.title_in_database).to eq("foo")
        end
      end

      instance.title = "bar"

      aggregate_failures "changed after save" do
        expect(instance.title_changed?).to eq(true)
        expect(instance.title_change).to eq(["foo", "bar"])
        expect(instance.title_was).to eq("foo")

        instance.save
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(instance.title_changed?).to eq(nil)
        else
          expect(instance.title_previously_changed?).to eq(true)
          expect(instance.title_previous_change).to eq(["foo", "bar"])
          expect(instance.title_changed?).to eq(false)
        end

        # AR-specific suffix methods
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
          expect(instance.saved_change_to_title?).to eq(true)
          expect(instance.saved_change_to_title).to eq(["foo", "bar"])
          expect(instance.title_before_last_save).to eq("foo")
          expect(instance.will_save_change_to_title?).to eq(false)
          expect(instance.title_change_to_be_saved).to eq(nil)
          expect(instance.title_in_database).to eq("bar")
        end
      end

      aggregate_failures "force change" do
        instance.title_will_change!

        aggregate_failures "before save" do
          expect(instance.title_changed?).to eq(true)

          # AR-specific suffix methods
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
            expect(instance.saved_change_to_title?).to eq(true)
            expect(instance.saved_change_to_title).to eq(["foo", "bar"])
            expect(instance.title_before_last_save).to eq("foo")
            expect(instance.will_save_change_to_title?).to eq(true)
            expect(instance.title_change_to_be_saved).to eq(["bar", "bar"])
            expect(instance.title_in_database).to eq("bar")
          end
        end

        instance.save!

        aggregate_failures "after save" do
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
            expect(instance.title_changed?).to eq(nil)
          else
            expect(instance.title_changed?).to eq(false)
          end

          # AR-specific suffix methods
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
            expect(instance.saved_change_to_title?).to eq(true)
            expect(instance.saved_change_to_title).to eq(["bar", "bar"])
            expect(instance.title_before_last_save).to eq("bar")
            expect(instance.will_save_change_to_title?).to eq(false)
            expect(instance.title_change_to_be_saved).to eq(nil)
            expect(instance.title_in_database).to eq("bar")
          end
        end
      end
    end

    it "returns changes on attribute for current locale" do
      instance = model_class.create(title: "foo")

      instance.title = "bar"

      aggregate_failures do
        expect(instance.title_changed?).to eq(true)
        expect(instance.title_change).to eq(["foo", "bar"])
        expect(instance.title_was).to eq("foo")

        Mobility.locale = :fr
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] < '5.0'
          expect(instance.title_changed?).to eq(nil)
        else
          expect(instance.title_changed?).to eq(false)
        end
        expect(instance.title_change).to eq(nil)
        expect(instance.title_was).to eq(nil)
      end
    end
  end

  describe "restoring attributes" do
    it "defines restore_<attribute>! for translated attributes" do
      Mobility.locale = :'pt-BR'
      instance = model_class.create

      instance.title = "foo"

      instance.restore_title!
      expect(instance.title).to eq(nil)
      expect(instance.changes).to eq({})
    end

    it "restores attribute when passed to restore_attribute!" do
      instance = model_class.create

      instance.title = "foo"
      instance.send :restore_attribute!, :title

      expect(instance.title).to eq(nil)
    end

    it "handles translated attributes when passed to restore_attributes" do
      instance = model_class.create(title: "foo")

      expect(instance.title).to eq("foo")

      instance.title = "bar"
      expect(instance.title).to eq("bar")
      instance.restore_attributes([:title])
      expect(instance.title).to eq("foo")
    end
  end

  describe "resetting original values hash on actions" do
    shared_examples_for "resets on model action" do |action|
      it "resets changes when model on #{action}" do
        instance = model_class.create

        aggregate_failures do
          instance.title = "foo"
          expect(instance.changes).to eq({ "title_en" => [nil, "foo"] })

          instance.send(action)

          # bypass the dirty module and set the variable directly
          instance.mobility_backends[:title].instance_variable_set(:@values, { :en => "bar" })

          expect(instance.title).to eq("bar")
          expect(instance.changes).to eq({})

          instance.title = nil
          expect(instance.changes).to eq({ "title_en" => ["bar", nil]})
        end
      end
    end

    it_behaves_like "resets on model action", :save
    it_behaves_like "resets on model action", :reload
  end

  if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
    describe "#saved_changes" do
      it "includes translated attributes" do
        instance = model_class.create

        instance.title = "foo en"
        Mobility.with_locale(:ja) { instance.title = "foo ja" }
        instance.save

        aggregate_failures do
          saved_changes = instance.saved_changes
          expect(saved_changes).to include("title_en", "title_ja")
          expect(saved_changes["title_en"]).to eq([nil, "foo en"])
          expect(saved_changes["title_ja"]).to eq([nil, "foo ja"])
        end
      end
    end
  end

  # Regression test for https://github.com/shioyama/mobility/issues/149
  describe "#_read_attribute" do
    it "is public" do
      instance = model_class.create
      expect { instance._read_attribute("foo") }.not_to raise_error
    end
  end
end if Mobility::Loaded::ActiveRecord
