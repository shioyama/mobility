require "spec_helper"
require "generator_spec/test_case"

describe Mobility::InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)

  after(:all) { prepare_destination }

  describe "no options" do
    before(:all) do
      prepare_destination
      run_generator
    end

    it "generates migration for translations table" do
      expect(destination_root).to have_structure {
        directory "db" do
          directory "migrate" do
            migration "create_translations" do
              contains "class CreateTranslations"
              contains "def change"
              contains "create_table :mobility_translations"
            end
          end
        end
      }
    end
  end

  describe "--without_table set to true" do
    before(:all) do
      prepare_destination
      run_generator %w(--without_table)
    end

    it "does not generate migration for translations table" do
      expect((Pathname.new(destination_root) + "db" + "migrate").exist?).to eq(false)
    end
  end
end
