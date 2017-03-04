require "spec_helper"

describe "Sequel::Plugins::Mobility", orm: :sequel do
  before do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
  end

  it "includes Mobility class" do
    Article.class_eval do
      plugin :mobility
      translates :title, backend: :table
    end
    expect(Article.ancestors).to include(Mobility)

    article = Article.new
    article.title = "foo"
    expect(article.title).to eq("foo")
  end
end
