require "spec_helper"

describe Mobility::TranslationsGenerator, type: :generator, orm: :active_record do
  require "generator_spec/test_case"
  include GeneratorSpec::TestCase
  require "generators/rails/mobility/translations_generator"

  destination File.expand_path("../tmp", __FILE__)

  after(:all) { prepare_destination }

  describe "--backend=table" do
    before(:all) do
      prepare_destination
      run_generator %w(Post title:string:index content:text --backend=table)
    end

    context "translations table does not yet exist" do
      it "generates table translations migration creating translations table" do
        expect(destination_root).to have_structure do
          directory "db" do
            directory "migrate" do
              migration "create_post_title_and_content_translations_for_mobility_table_backend" do
                contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration[5.0]"
                contains "def change"
                contains "create_table :post_translations"
                contains "t.string :title"
                contains "t.text :content"
                contains "t.string  :locale, null: false"
                contains "t.integer :post_id, null: false"
                contains "t.timestamps null: false"
                contains "add_index :post_translations, :post_id, name: :index_post_translations_on_post_id"
                contains "add_index :post_translations, :locale, name: :index_post_translations_on_locale"
                contains "add_index :post_translations, [:post_id, :locale], name: :index_post_translations_on_post_id_and_locale, unique: true"
                contains "add_index :post_translations, :title"
              end
            end
          end
        end
      end
    end

    context "translation table already exists" do
      before { ActiveRecord::Base.connection.create_table :post_translations }

      it "generates table translations migration adding columns to existing translations table" do
        expect(destination_root).to have_structure do
          directory "db" do
            directory "migrate" do
              migration "create_post_title_and_content_translations_for_mobility_table_backend" do
                contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration[5.0]"
                contains "add_column :post_translations, :title, :string"
                contains "add_index :post_translations, :title"
                contains "add_column :post_translations, :content, :text"
              end
            end
          end
        end
      end
    end
  end

  describe "--backend=column" do
    before { prepare_destination }

    context "model table does not exist" do
      it "raises NoTableDefined error" do
        expect { run_generator %w(Foo title:string:index content:text --backend=column) }.to raise_error(Mobility::BackendGenerators::NoTableDefined)
      end
    end

    context "model table exists" do
      before do
        ActiveRecord::Base.connection.create_table :foos
        available_locales = I18n.available_locales
        I18n.available_locales = [:en, :ja, :de]
        run_generator %w(Foo title:string:index content:text --backend=column)
        I18n.available_locales = available_locales
      end

      it "generates column translations migration adding columns for each locale to model table" do
        expect(destination_root).to have_structure do
          directory "db" do
            directory "migrate" do
              migration "create_foo_title_and_content_translations_for_mobility_column_backend" do
                contains "class CreateFooTitleAndContentTranslationsForMobilityColumnBackend < ActiveRecord::Migration[5.0]"
                contains "add_column :foos, :title_en, :string"
                contains "add_index :foos, :title_en"
                contains "add_column :foos, :title_ja, :string"
                contains "add_index :foos, :title_ja"
                contains "add_column :foos, :title_de, :string"
                contains "add_index :foos, :title_de"
                contains "add_column :foos, :content_en, :text"
                contains "add_column :foos, :content_ja, :text"
                contains "add_column :foos, :content_de, :text"
              end
            end
          end
        end
      end
    end
  end
end if Mobility::Loaded::Rails
