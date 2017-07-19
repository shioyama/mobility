require "spec_helper"

describe Mobility::Backend::OrmDelegator do
  before do
    stub_const 'Mobility::MyClass', Module.new
    Mobility::MyClass.extend described_class
    stub_const 'Mobility::ActiveRecord::MyClass', Class.new
    stub_const 'Mobility::Sequel::MyClass', Class.new
  end
  subject { Mobility::MyClass }

  context "No ORM model const defined", orm: :none do
    describe ".for" do
      it "raises ArgumentError with correct message" do
        expect {
          subject.for(Class.new)
        }.to raise_error(ArgumentError, "MyClass backend can only be used by ActiveRecord or Sequel models")
      end
    end
  end

  context "ActiveRecord const defined", orm: :active_record do
    describe ".for" do
      it "raises ArgumentError with correct message when model does not inherit from ActiveRecord::Base" do
        expect {
          subject.for(Class.new)
        }.to raise_error(ArgumentError, "MyClass backend can only be used by ActiveRecord or Sequel models")
      end

      it "returns ActiveRecord::MyClass when model inherits from ActiveRecord" do
        expect(subject.for(Class.new(::ActiveRecord::Base))).to eq(Mobility::ActiveRecord::MyClass)
      end
    end
  end

  context "Sequel const defined", orm: :sequel do
    describe ".for" do
      it "raises ArgumentError with correct message when model does not inherit from Sequel::Model" do
        expect {
          subject.for(Class.new)
        }.to raise_error(ArgumentError, "MyClass backend can only be used by ActiveRecord or Sequel models")
      end

      it "returns Sequel::MyClass when model inherits from Sequel::Model" do
        expect(subject.for(Class.new(::Sequel::Model))).to eq(Mobility::Sequel::MyClass)
      end
    end
  end
end
