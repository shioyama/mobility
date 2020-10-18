require "spec_helper"

describe "Sequel::Plugins::Mobility", orm: :sequel do
  include Helpers::Plugins

  plugins :sequel, :reader, :writer

  before { stub_const 'Article', Class.new(Sequel::Model) }

  it "includes Mobility class" do
    Article.plugin :mobility

    expect(Article.ancestors).to include(Mobility)
  end
end
