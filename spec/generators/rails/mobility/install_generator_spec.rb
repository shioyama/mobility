require "spec_helper"

return unless defined?(Rails)

require "rails/generators/mobility/install_generator"

describe Mobility::InstallGenerator, type: :generator do
  require "generator_spec/test_case"
  include GeneratorSpec::TestCase
  include Helpers::Generators

  destination File.expand_path("../tmp", __FILE__)

  after(:all) { prepare_destination }

  describe "no options" do
    before(:all) do
      prepare_destination
      run_generator
    end

    it "generates initializer" do
      expect(destination_root).to have_structure {
        directory "config" do
          directory "initializers" do
            file "mobility.rb" do
              contains "Mobility.configure do"
              contains "plugins do"
              contains "backend :key_value"
              contains "backend_reader"
              contains "query"
            end
          end
        end
      }
    end

    it "generates migration for text translations table" do
      version_string_ = version_string

      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_text_translations" do
              contains "class CreateTextTranslations < ActiveRecord::Migration[#{version_string_}]"
              contains "def change"
              contains "create_table :mobility_text_translations"
              contains "t.text :value"
              contains "t.references :translatable, polymorphic: true, index: false"
              contains "add_index :mobility_text_translations"
              contains "name: :index_mobility_text_translations_on_keys"
              contains "name: :index_mobility_text_translations_on_translatable_attribute"
            end
          end
        end
      }
    end

    it "generates migration for string translations table" do
      version_string_ = version_string

      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_string_translations" do
              contains "class CreateStringTranslations < ActiveRecord::Migration[#{version_string_}]"
              contains "def change"
              contains "create_table :mobility_string_translations"
              contains "t.string :value"
              contains "t.references :translatable, polymorphic: true, index: false"
              contains "add_index :mobility_string_translations"
              contains "name: :index_mobility_string_translations_on_keys"
              contains "name: :index_mobility_string_translations_on_translatable_attribute"
              contains "name: :index_mobility_string_translations_on_query_keys"
            end
          end
        end
      }
    end
  end

  describe "--without_tables set to true" do
    before(:all) do
      prepare_destination
      run_generator %w(--without_tables)
    end

    it "does not generate migration for translations tables" do
      expect((Pathname.new(destination_root) + "db" + "migrate").exist?).to eq(false)
    end
  end
end
