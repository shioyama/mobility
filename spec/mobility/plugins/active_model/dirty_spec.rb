require "spec_helper"

describe "Mobility::Plugins::ActiveModel::Dirty", orm: :active_record do
  require "mobility/plugins/active_model/dirty"

  include Helpers::Plugins
  plugin_setup dirty: true

  def define_backend_class
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

  let(:model_class) do
    stub_const 'Article', Class.new {
      def save
        changes_applied
      end
    }
    Article.include ActiveModel::Dirty
    Article.include attributes
    Article
  end
  let(:backend_class) { define_backend_class }

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
      instance.title = "foo"
      instance.save

      aggregate_failures do
        instance.title = "bar"
        expect(instance.changed?).to eq(true)

        instance.save

        expect(instance.changed?).to eq(false)
        expect(instance.previous_changes).to eq({ "title_en" => ["foo", "bar"]})
      end
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
      instance.title_en = "English title 1"
      instance.title_fr = "Titre en Francais 1"
      instance.save

      instance.title = "English title 2"
      Mobility.locale = :fr
      instance.title = "Titre en Francais 2"

      instance.save

      expect(instance.previous_changes).to eq({"title_en" => ["English title 1", "English title 2"],
                                              "title_fr" => ["Titre en Francais 1", "Titre en Francais 2"]})
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
    it "defines suffix methods on translated attribute", rails_version_geq: '5.0' do
      instance.title = "foo"
      instance.save

      instance.title = "bar"

      aggregate_failures do
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

        instance.title_will_change!
        expect(instance.title_changed?).to eq(true)
      end
    end

    it "returns changes on attribute for current locale", rails_version_geq: '5.0' do
      instance.title = "foo"
      instance.save

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
      instance.save

      instance.title = "foo"

      instance.restore_title!
      expect(instance.title).to eq(nil)
      expect(instance.changes).to eq({})
    end

    it "restores attribute when passed to restore_attribute!" do
      instance.save

      instance.title = "foo"
      instance.send :restore_attribute!, :title

      expect(instance.title).to eq(nil)
    end

    it "handles translated attributes when passed to restore_attributes" do
      instance.title = "foo"
      instance.save

      expect(instance.title).to eq("foo")

      instance.title = "bar"
      expect(instance.title).to eq("bar")
      instance.restore_attributes([:title])
      expect(instance.title).to eq("foo")
    end
  end

  describe "fallbacks compatiblity" do
    plugin_setup dirty: true, fallbacks: { en: 'ja' }

    let(:model_class) do
      stub_const 'ArticleWithFallbacks', Class.new
      ArticleWithFallbacks.include ActiveModel::Dirty
      ArticleWithFallbacks.include attributes
      ArticleWithFallbacks
    end

    let(:backend_class) { define_backend_class }

    it "does not compare with fallback value" do
      aggregate_failures "before change" do
        expect(instance.title).to eq(nil)
        expect(instance.changed?).to eq(false)
        expect(instance.changed).to eq([])
        expect(instance.changes).to eq({})
      end

      aggregate_failures "set fallback locale value" do
        Mobility.with_locale(:ja) { instance.title = "あああ" }
        expect(instance.title).to eq("あああ")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_ja"])
        expect(instance.changes).to eq({ "title_ja" => [nil, "あああ"]})
        Mobility.with_locale(:ja) { expect(instance.title).to eq("あああ") }
      end

      aggregate_failures "set value in current locale to same value" do
        instance.title = nil
        expect(instance.title).to eq("あああ")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_ja"])
        expect(instance.changes).to eq({ "title_ja" => [nil, "あああ"]})
      end

      aggregate_failures "set value in fallback locale to different value" do
        Mobility.with_locale(:ja) { instance.title = "ばばば" }
        expect(instance.title).to eq("ばばば")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to eq(["title_ja"])
        expect(instance.changes).to eq({ "title_ja" => [nil, "ばばば"]})
      end

      aggregate_failures "set value in current locale to different value" do
        instance.title = "Title"
        expect(instance.title).to eq("Title")
        expect(instance.changed?).to eq(true)
        expect(instance.changed).to match_array(["title_ja", "title_en"])
        expect(instance.changes).to eq({ "title_ja" => [nil, "ばばば"], "title_en" => [nil, "Title"]})
      end
    end
  end
end if Mobility::Loaded::ActiveRecord
