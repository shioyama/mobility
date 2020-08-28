require "spec_helper"

describe "Sequel::Plugins::Mobility", orm: :sequel do
  include Helpers::Plugins

  plugins :sequel, :reader, :writer

  before do
    stub_const 'Article', Class.new(Sequel::Model)
    Article.dataset = DB[:articles]
  end

  it "includes Mobility class" do
    Article.plugin :mobility
    Article.translates :title, backend: :table

    expect(Article.ancestors).to include(Mobility)
  end
end
