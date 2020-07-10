require "spec_helper"

describe Mobility::TranslationsGenerator, type: :generator, orm: :active_record do
  require "generator_spec/test_case"
  include GeneratorSpec::TestCase
  include Helpers::Generators
  require "rails/generators/mobility/translations_generator"

  destination File.expand_path("../tmp", __FILE__)

  after(:all) { prepare_destination }

  describe "--backend=table" do
    after(:each) { connection.drop_table :post_translations if connection.data_source_exists?(:post_translations) }

    let(:setup_generator) do
      prepare_destination
      run_generator %w(Post title:string:index content:text --backend=table)
    end

    shared_examples_for "long index name truncator" do
      it "truncates index to length required by database" do
        # Choose maximum length attribute name such that without truncation its full index name will be too long for db
        name = 'a'*(connection.allowed_index_name_length - "index_post_translations_on_".length - "_and_locale".length)

        prepare_destination
        run_generator ["Post", "#{name}:string:index", "--backend=table"]

        expect(destination_root).to have_structure {
          directory "db" do
            directory "migrate" do
              migration "create_post_#{name}_translations_for_mobility_table_backend" do
                contains "add_index :post_translations, [:#{name}, :locale], name: :index_"
              end
            end
          end
        }

        load Dir[File.join(destination_root, "**", "*.rb")].first
        migration = "CreatePost#{name.capitalize}TranslationsForMobilityTableBackend".constantize.new
        migration.verbose = false

        # check that migrating doesn't raise an error
        expect { migration.migrate :up }.not_to raise_error

        index = connection.indexes("post_translations").find { |i| i.columns.include? name }
        expect(index).not_to be_nil
        expect(index.name).to match /^index_[a-z0-9]{40}$/
      end
    end

    context "translations table does not yet exist" do
      it "generates table translations migration creating translations table" do
        version_string_ = version_string
        setup_generator

        expect(destination_root).to have_structure {
          directory "db" do
            directory "migrate" do
              migration "create_post_title_and_content_translations_for_mobility_table_backend" do
                if ENV["RAILS_VERSION"] < "5.0"
                  contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration"
                else
                  contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration[#{version_string_}]"
                end
                contains "def change"
                contains "create_table :post_translations"
                contains "t.string :title"
                contains "t.text :content"
                contains "t.string  :locale, null: false"
                contains "t.references :post, null: false, foreign_key: true, index: false"
                contains "t.timestamps null: false"
                contains "add_index :post_translations, :locale, name: :index_post_translations_on_locale"
                contains "add_index :post_translations, [:post_id, :locale], name: :index_post_translations_on_post_id_and_locale, unique: true"
                contains "add_index :post_translations, [:title, :locale], name: :index_post_translations_on_title_and_locale"
              end
            end
          end
        }
      end

      context "index name is too long for database", db: [:mysql, :postgres] do
        it_behaves_like "long index name truncator"
      end
    end

    context "translation table already exists" do
      before do
        connection.create_table :post_translations do |t|
          t.string :locale
          t.integer :post_id, null: false
          t.timestamps null: false
        end
      end

      it "generates table translations migration adding columns to existing translations table" do
        version_string_ = version_string
        setup_generator

        expect(destination_root).to have_structure {
          directory "db" do
            directory "migrate" do
              migration "create_post_title_and_content_translations_for_mobility_table_backend" do
                if ENV["RAILS_VERSION"] < "5.0"
                  contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration"
                else
                  contains "class CreatePostTitleAndContentTranslationsForMobilityTableBackend < ActiveRecord::Migration[#{version_string_}]"
                end
                contains "add_column :post_translations, :title, :string"
                contains "add_index :post_translations, [:title, :locale], name: :index_post_translations_on_title_and_locale"
                contains "add_column :post_translations, :content, :text"
              end
            end
          end
        }
      end

      context "index name is too long for database", db: [:mysql, :postgres] do
        it_behaves_like "long index name truncator"
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
        @available_locales = I18n.available_locales
        connection.create_table :foos
        I18n.available_locales = [:en, :ja, :de]
        run_generator %w(Foo title:string:index content:text --backend=column)
      end
      after do
        I18n.available_locales = @available_locales
        connection.drop_table :foos
      end

      it "generates column translations migration adding columns for each locale to model table" do
        version_string_ = version_string

        expect(destination_root).to have_structure {
          directory "db" do
            directory "migrate" do
              migration "create_foo_title_and_content_translations_for_mobility_column_backend" do
                if ENV["RAILS_VERSION"] < "5.0"
                  contains "class CreateFooTitleAndContentTranslationsForMobilityColumnBackend < ActiveRecord::Migration"
                else
                  contains "class CreateFooTitleAndContentTranslationsForMobilityColumnBackend < ActiveRecord::Migration[#{version_string_}]"
                end
                contains "add_column :foos, :title_en, :string"
                contains "add_index  :foos, :title_en, name: :index_foos_on_title_en"
                contains "add_column :foos, :title_ja, :string"
                contains "add_index  :foos, :title_ja, name: :index_foos_on_title_ja"
                contains "add_column :foos, :title_de, :string"
                contains "add_index  :foos, :title_de, name: :index_foos_on_title_de"
                contains "add_column :foos, :content_en, :text"
                contains "add_column :foos, :content_ja, :text"
                contains "add_column :foos, :content_de, :text"
              end
            end
          end
        }
      end
    end
  end

  shared_examples_for "backend with no translations generator" do |backend_name|
    before { prepare_destination }

    it "returns correct message" do
      out = capture(:stderr) { run_generator ["Foo", "--backend=#{backend_name}"] }
      expect(out.chomp).to include("The #{backend_name} backend does not have a translations generator.")
    end
  end

  %w[hstore json jsonb serialized key_value container].each do |backend_name|
    describe "--backend=#{backend_name}" do
      it_behaves_like "backend with no translations generator", backend_name
    end
  end

  def connection
    ActiveRecord::Base.connection
  end
end if defined?(Rails)
