require "spec_helper"

describe "Mobility::ActiveRecord", orm: :active_record do
  before do
    stub_const 'MyModel', ActiveRecord::Base
    MyModel.include Mobility::ActiveRecord
  end

  describe ".i18n" do
    it "extends class with .i18n scope method" do
      scope = double('scope')
      expect(MyModel).to receive(:all).and_return(scope)

      expect(MyModel.i18n).to eq(scope)
    end
  end
end
