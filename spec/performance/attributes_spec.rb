require "spec_helper"

describe Mobility::Attributes do
  describe "initializing" do
    specify {
      expect { described_class.new(backend: :null) }.to allocate_under(10).objects
    }
  end

  describe "including into a class" do
    specify {
      klass = Class.new do
        extend Mobility
      end
      attributes = described_class.new(backend: :null)
      expect { klass.include attributes }.to allocate_under(155).objects
    }
  end

  describe "accessors" do
    let(:klass) do
      Class.new do
        include Mobility
        translates :title, backend: :null
      end
    end

    describe "calling attribute getter" do
      specify {
        instance = klass.new
        expect { 3.times { instance.title } }.to allocate_under(20).objects
      }
    end

    describe "calling attribute setter" do
      specify {
        instance = klass.new
        title = "foo"
        expect { 3.times { instance.title = title } }.to allocate_under(14).objects
      }
    end
  end
end
