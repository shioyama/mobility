require "spec_helper"

describe "Mobility::Plugins::ActiveRecord::Dirty", orm: :active_record do
  include Helpers::Plugins
  plugin_setup "title", dirty: true, active_record: true, reader: true, writer: true

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
        values[locale]
      end

      def write(locale, value, **)
        values[locale] = value
      end

      private
      def values; @values ||= {}; end
    end
  end

  describe "tracking changes" do
    it "tracks changes in one locale" do
      Mobility.locale = locale = :'pt-BR'

      aggregate_failures "before change" do
        expect(backend.read(locale)).to eq(nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      aggregate_failures "set same value" do
        backend.write(locale, nil)
        expect(backend.read(locale)).to eq(nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      backend.write(locale, 'foo')

      aggregate_failures "after change" do
        expect(backend.read(locale)).to eq("foo")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_pt_br"])
        expect(instance.changes).to eq({ "title_pt_br" => [nil, "foo"] })
      end
    end

    it "tracks previous changes in one locale" do
      Mobility.locale = locale = :en
      instance = model_class.create(title: "foo")

      aggregate_failures do
        backend_for(instance, :title).write(:en, "bar")
        expect(instance.changed?).to eq(true)

        instance.save

        expect(instance.changed?).to eq(false)
        expect(instance.previous_changes).to include({ "title_en" => ["foo", "bar"]})
      end
    end

    it "tracks previous changes in one locale in before_save hook" do
      Mobility.locale = locale = :en
      instance = model_class.create(title: "foo")

      backend_for(instance, :title).write(locale, 'bar')
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
      Mobility.locale = locale = :en
      expect(backend.read(locale)).to eq(nil)

      aggregate_failures "change in English locale" do
        backend.write(locale, "English title")

        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_en"])
        expect(instance.changes).to eq({ "title_en" => [nil, "English title"] })
      end

      aggregate_failures "change in French locale" do
        Mobility.locale = locale = :fr

        backend.write(locale, "Titre en Francais")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to match_array(["title_en", "title_fr"])
        expect(instance.changes).to eq({ "title_en" => [nil, "English title"], "title_fr" => [nil, "Titre en Francais"] })
      end
    end

    it "tracks previous changes in multiple locales" do
      Mobility.locale = :en
      instance = model_class.create(title_en: "English title 1", title_fr: "Titre en Francais 1")

      backend = backend_for(instance, :title)

      backend.write(:en, "English title 2")
      backend.write(:fr, "Titre en Francais 2")

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
        expect(instance.content_changed?).to eq(false)
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
      Mobility.locale = locale = :en
      expect(instance.changed?).to eq(false)

      aggregate_failures "after change" do
        backend.write(locale, "foo")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_en"])
        expect(instance.changes).to eq({ "title_en" => [nil, "foo"] })
      end

      aggregate_failures "after setting attribute back to original value" do
        backend.write(locale, nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      aggregate_failures "changing value in different locale" do
        backend.write(:fr, "Titre en Francais")

        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_fr"])
        expect(instance.changes).to eq({ "title_fr" => [nil, "Titre en Francais"] })
      end
    end
  end

  describe "suffix methods" do
    it "defines suffix methods on translated attribute" do
      Mobility.locale = :en
      backend.write(:en, 'foo')

      instance.save
      aggregate_failures "after save" do
        expect(instance.changed?).to eq(false)
        expect(instance.title_change).to eq(nil)
        expect(instance.title_changed?).to eq(false)
        expect(instance.title_was).to eq("foo")

        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] >= '5.0'
          expect(instance.title_previously_changed?).to eq(true)
          expect(instance.title_previous_change).to eq([nil, "foo"])
        end

        # AR-specific suffix methods, added in AR 5.1
        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
          expect(instance.saved_change_to_title?).to eq(true)
          expect(instance.saved_change_to_title).to eq([nil, "foo"])
          expect(instance.title_before_last_save).to eq(nil)
          expect(instance.title_in_database).to eq("foo")

          # attribute handlers
          expect(instance.saved_change_to_attribute?(:title_en)).to eq(true)
          expect(instance.saved_change_to_attribute(:title_en)).to eq([nil, 'foo'])
          expect(instance.attribute_before_last_save(:title_en)).to eq(nil)
          expect(instance.attribute_in_database(:title_en)).to eq('foo')
        end
      end

      backend.write(:en, 'bar')

      aggregate_failures "changed after save" do
        expect(instance.title_changed?).to eq(true)
        expect(instance.title_change).to eq(["foo", "bar"])
        expect(instance.title_was).to eq("foo")

        instance.save

        expect(instance.title_changed?).to eq(false)

        if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] >= '5.0'
          expect(instance.title_previously_changed?).to eq(true)
          expect(instance.title_previous_change).to eq(["foo", "bar"])
          expect(instance.title_changed?).to eq(false)

          # AR-specific suffix methods, added in 5.1
          if ENV['RAILS_VERSION'] > '5.0'
            expect(instance.saved_change_to_title?).to eq(true)
            expect(instance.saved_change_to_title).to eq(["foo", "bar"])
            expect(instance.title_before_last_save).to eq("foo")
            expect(instance.will_save_change_to_title?).to eq(false)
            expect(instance.title_change_to_be_saved).to eq(nil)
            expect(instance.title_in_database).to eq("bar")

            # attribute handlers
            expect(instance.saved_change_to_attribute?(:title_en)).to eq(true)
            expect(instance.saved_change_to_attribute(:title_en)).to eq(['foo', 'bar'])
            expect(instance.attribute_before_last_save(:title_en)).to eq('foo')
            expect(instance.will_save_change_to_attribute?(:title_en)).to eq(false)
            expect(instance.attribute_change_to_be_saved(:title_en)).to eq(nil)
            expect(instance.attribute_in_database(:title_en)).to eq('bar')
          end
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

            expect(instance.saved_change_to_attribute?(:title_en)).to eq(true)
            expect(instance.saved_change_to_attribute(:title_en)).to eq(['foo', 'bar'])
            expect(instance.attribute_before_last_save(:title_en)).to eq('foo')
            expect(instance.will_save_change_to_attribute?(:title_en)).to eq(true)
            expect(instance.attribute_change_to_be_saved(:title_en)).to eq(['bar', 'bar'])
            expect(instance.attribute_in_database(:title_en)).to eq('bar')
          end
        end

        instance.save!

        aggregate_failures "after save" do
          expect(instance.title_changed?).to eq(false)

          # AR-specific suffix methods, added in 5.1
          if ENV['RAILS_VERSION'].present? && ENV['RAILS_VERSION'] > '5.0'
            expect(instance.saved_change_to_title?).to eq(true)
            expect(instance.saved_change_to_title).to eq(["bar", "bar"])
            expect(instance.title_before_last_save).to eq("bar")
            expect(instance.will_save_change_to_title?).to eq(false)
            expect(instance.title_change_to_be_saved).to eq(nil)
            expect(instance.title_in_database).to eq("bar")

            expect(instance.saved_change_to_attribute?(:title_en)).to eq(true)
            expect(instance.saved_change_to_attribute(:title_en)).to eq(['bar', 'bar'])
            expect(instance.attribute_before_last_save(:title_en)).to eq('bar')
            expect(instance.will_save_change_to_attribute?(:title_en)).to eq(false)
            expect(instance.attribute_change_to_be_saved(:title_en)).to eq(nil)
            expect(instance.attribute_in_database(:title_en)).to eq('bar')
          end
        end
      end
    end

    it "returns changes on attribute for current locale" do
      instance = model_class.create(title: "foo")

      backend = backend_for(instance, :title)
      backend.write(:en, "bar")

      aggregate_failures do
        expect(instance.title_changed?).to eq(true)
        expect(instance.title_change).to eq(["foo", "bar"])
        expect(instance.title_was).to eq("foo")

        Mobility.locale = :fr
        expect(instance.title_changed?).to eq(false)
        expect(instance.title_change).to eq(nil)
        expect(instance.title_was).to eq(nil)
      end
    end
  end

  %w[changes_applied clear_attribute_changes clear_changes_information].each do |method_name|
    it "does not change visibility of #{method_name}" do
      # Create a dummy AR model so we can inspect its dirty methods. This way
      # test works for all versions of Rails (private/public status of these
      # methods has changed between versions.)
      klass = Class.new do
        def self.after_create; end
        def self.after_update; end

        include ::ActiveRecord::AttributeMethods::Dirty
      end
      dirty = klass.new

      expect(instance.respond_to?(method_name)).to eq(dirty.respond_to?(method_name))
      expect(instance.respond_to?(method_name, true)).to eq(dirty.respond_to?(method_name, true))
    end
  end

  describe "restoring attributes" do
    it "defines restore_<attribute>! for translated attributes" do
      Mobility.locale = locale = :'pt-BR'
      instance = model_class.create

      backend.write(locale, 'foo')

      instance.restore_title!
      expect(instance.title).to eq(nil)
      expect(instance.changes).to eq({})
    end

    it "restores attribute when passed to restore_attribute!" do
      instance = model_class.create

      backend.write(:en, "foo")
      instance.send :restore_attribute!, :title

      expect(instance.title).to eq(nil)
    end

    it "handles translated attributes when passed to restore_attributes" do
      instance = model_class.create(title: "foo")
      backend = backend_for(instance, :title)

      expect(backend.read(:en)).to eq("foo")

      backend.write(:en, 'bar')
      expect(backend.read(:en)).to eq("bar")
      instance.restore_attributes([:title])
      expect(backend.read(:en)).to eq("foo")
    end
  end

  describe "resetting original values hash on actions" do
    shared_examples_for "resets on model action" do |action|
      it "resets changes when model on #{action}" do
        instance = model_class.create
        backend = backend_for(instance, :title)

        aggregate_failures do
          backend.write(:en, 'foo')
          expect(instance.changes).to eq({ "title_en" => [nil, "foo"] })

          instance.send(action)

          # bypass the dirty module and set the variable directly
          instance.mobility_backends[:title].instance_variable_set(:@values, { :en => "bar" })

          expect(backend.read(:en)).to eq("bar")
          expect(instance.changes).to eq({})

          backend.write(:en, nil)
          expect(instance.changes).to eq({ "title_en" => ["bar", nil]})
        end
      end
    end

    it_behaves_like "resets on model action", :save
    it_behaves_like "resets on model action", :reload
  end

  describe "#saved_changes", rails_version_geq: '5.1' do
    it "includes translated and untranslated attributes" do
      instance = model_class.create

      instance.title_en = "foo en"
      instance.title_ja = "foo ja"
      instance.published = false
      instance.save

      aggregate_failures do
        saved_changes = instance.saved_changes
        expect(saved_changes).to include('title_en', 'title_ja', 'published')
        expect(saved_changes['title_en']).to eq([nil, "foo en"])
        expect(saved_changes['title_ja']).to eq([nil, "foo ja"])
        expect(saved_changes['published']).to eq([nil, false])
      end
    end
  end

  describe '#changes_to_save', rails_version_geq: '5.1' do
    it "includes translated and untranslated attributes" do
      instance = model_class.new

      instance.title_en = "foo en"
      instance.title_ja = "foo ja"
      instance.published = false

      expect(instance.changes_to_save).to eq({
        'title_en' => [nil, 'foo en'],
        'title_ja' => [nil, 'foo ja'],
        'published' => [nil, false]
      })
    end
  end

  describe '#has_changes_to_save?', rails_version_geq: '6.0' do
    it 'detects changes to translated and untranslated attributes' do
      instance = model_class.new
      backend = backend_for(instance, :title)

      expect(instance.has_changes_to_save?).to eq(false)

      backend.write(:en, 'foo en')
      expect(instance.has_changes_to_save?).to eq(true)

      instance = model_class.new
      instance.published = false
      expect(instance.has_changes_to_save?).to eq(true)
    end
  end

  describe '#attributes_in_database', rails_version_geq: '6.0' do
    it 'includes translated and untranslated attributes' do
      instance = model_class.create
      expect(instance.attributes_in_database).to eq({})

      instance.title_en = 'foo en'
      expect(instance.attributes_in_database).to eq({ 'title_en' => nil })

      instance.title_ja = 'foo ja'
      expect(instance.attributes_in_database).to eq({ 'title_en' => nil, 'title_ja' => nil })

      instance.published = false
      expect(instance.attributes_in_database).to eq({ 'title_en' => nil, 'title_ja' => nil, 'published' => nil })

      instance.save
      instance.title_en = 'foo en 2'
      instance.title_ja = 'foo ja 2'
      instance.published = true
      expect(instance.attributes_in_database).to eq({ 'title_en' => 'foo en', 'title_ja' => 'foo ja', 'published' => false })
    end
  end

  describe '#changed_attribute_names_to_save', rails_version_geq: '5.1' do
    it 'includes translated attributes and untranslated attributes' do
      instance = model_class.new
      backend = backend_for(instance, :title)
      expect(instance.changed_attribute_names_to_save).to eq([])

      backend.write(:en, 'foo en')
      expect(instance.changed_attribute_names_to_save).to eq(%w[title_en])

      backend.write(:ja, 'foo ja')
      expect(instance.changed_attribute_names_to_save).to match_array(%w[title_en title_ja])

      instance.published = false
      expect(instance.changed_attribute_names_to_save).to match_array(%w[title_en title_ja published])
    end
  end
end
