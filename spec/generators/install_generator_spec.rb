require "spec_helper"

describe Mobility::InstallGenerator, type: :generator, orm: :active_record do
  break unless Mobility::Loaded::Rails

  require "generator_spec/test_case"
  include GeneratorSpec::TestCase

  destination File.expand_path("../tmp", __FILE__)

  after(:all) { prepare_destination }

  describe "no options" do
    before(:all) do
      prepare_destination
      run_generator
    end

    it "generates migration for text translations table" do
      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_text_translations" do
              contains "class CreateTextTranslations"
              contains "def change"
              contains "create_table :mobility_text_translations"
              contains "t.text    :value"
              contains "add_index :mobility_text_translations"
              contains "name: :index_mobility_text_translations_on_keys"
              contains "name: :index_mobility_text_translations_on_translatable"
            end
          end
        end
      }
    end

    it "generates migration for string translations table" do
      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_string_translations" do
              contains "class CreateStringTranslations"
              contains "def change"
              contains "create_table :mobility_string_translations"
              contains "t.string  :value"
              contains "add_index :mobility_string_translations"
              contains "name: :index_mobility_string_translations_on_keys"
              contains "name: :index_mobility_string_translations_on_translatable"
            end
          end
        end
      }
    end
  end

  describe "--without_table set to true" do
    before(:all) do
      prepare_destination
      run_generator %w(--without_tables)
    end

    it "does not generate migration for translations tables" do
      expect((Pathname.new(destination_root) + "db" + "migrate").exist?).to eq(false)
    end
  end
end
