require "spec_helper"

#TODO: Add general compatibility specs for Sequel
describe "Sequel compatibility", orm: :sequel do
  include Helpers::Plugins
  include Helpers::Translates
  # Enable all plugins that are enabled by default pre v1.0
  plugins :sequel, :reader, :writer, :cache, :dirty, :presence, :query, :fallbacks

  before do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
    Article
  end

  describe "querying on translated and untranslated attributes" do
    %i[key_value table].each do |backend|
      #TODO: update querying examples to correctly test untranslated attributes
      context "#{backend} backend" do
        before do
          options = { backend: backend, fallbacks: false }
          options[:type] = :string if backend == :key_value
          translates Article, :title, **options
        end
        let!(:article1) { Article.create(title: "foo", slug: "bar") }
        let!(:article2) { Article.create(              slug: "baz") }
        let!(:article4) { Article.create(title: "foo"             ) }

        it "works with hash arguments" do
          expect(Article.i18n.where(title: "foo", slug: "bar").select_all(:articles).all).to eq([article1])
          expect(Article.i18n.where(title: "foo"             ).select_all(:articles).all).to match_array([article1, article4])
          expect(Article.i18n.where(title: "foo", slug: "baz").select_all(:articles).all).to eq([])
          expect(Article.i18n.where(              slug: "baz").select_all(:articles).all).to match_array([article2])
        end

        it "works with virtual rows" do
          expect(Article.i18n { (title =~ "foo") & (slug =~ "bar") }.select_all(:articles).all).to eq([article1])
          expect(Article.i18n { (title =~ "foo")                   }.select_all(:articles).all).to match_array([article1, article4])
          expect(Article.i18n { (title =~ "foo") & (slug =~ "baz") }.select_all(:articles).all).to eq([])
          expect(Article.i18n {                    (slug =~ "baz") }.select_all(:articles).all).to eq([article2])
        end
      end
    end
  end
end
