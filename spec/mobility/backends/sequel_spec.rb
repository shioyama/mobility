require "spec_helper"

describe "Mobility::Backends::Sequel", orm: :sequel do
  context "model with multiple backends" do
    before do
      stub_const 'Comment', Class.new(Sequel::Model)
      Comment.dataset = DB[:comments]
      Comment.extend Mobility
      Comment.translates :content, backend: :column
      Comment.translates :title, :author, backend: :key_value, type: :text
      @comment1 = Comment.create(content: "foo content 1", title: "foo title 1", author: "Foo author 1")
      @comment2 = Comment.create(                          title: "foo title 2", author: "Foo author 2")
      Mobility.with_locale(:ja) { @comment1.update(content: "コンテンツ 1", title: "タイトル 1", author: "オーサー 1") }
      Mobility.with_locale(:ja) { @comment2.update(content: "コンテンツ 2",                      author: "オーサー 2") }
      @comment3 = Comment.create(content: "foo content 1")
      @comment4 = Comment.create(content: "foo content 2", title: "foo title 2", author: "Foo author 3")
    end

    describe ".i18n (mobility scope)" do
      describe ".where" do
        it "works with multiple backends" do
          expect(Comment.i18n.where(content: "foo content 1", title: "foo title 1").select_all(:comments).map(&:id)).to eq([@comment1.id])
          expect(Comment.i18n.where(content: "foo content 1", title: nil).select_all(:comments).map(&:id)).to eq([@comment3.id])

          Mobility.locale = :ja
          expect(Comment.i18n.where(content: "foo content 1", title: "foo title 1").select_all(:comments).all).to eq([])
          expect(Comment.i18n.where(content: "コンテンツ 1", title: "タイトル 1").select_all(:comments).map(&:id)).to eq([@comment1.id])
        end
      end
    end
  end
end if defined?(Sequel)
