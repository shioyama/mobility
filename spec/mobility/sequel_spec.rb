require "spec_helper"

describe Mobility::Sequel, orm: :sequel do
  before do
    stub_const 'MyModel', Sequel::Model
    MyModel.include Mobility::Sequel
  end

  describe ".i18n" do
    it "extends class with .i18n dataset method" do
      dataset = double('dataset')
      expect(MyModel).to receive(:dataset).and_return(dataset)

      expect(MyModel.i18n).to eq(dataset)
    end
  end
end if Mobility::Loaded::Sequel
