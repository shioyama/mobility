require "spec_helper"

describe Mobility::Attributes, orm: 'none' do
  describe "initializing" do
    specify {
      expect { described_class.new(backend: :null) }.to allocate_under(25).objects
    }
  end

  describe "including into a class" do
    specify {
      klass = Class.new do
        extend Mobility
      end
      expect {
        klass.include(described_class.new(backend: :null))
      }.to allocate_under(170).objects
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
        expect { 3.times { instance.title = title } }.to allocate_under(20).objects
      }
    end
  end
end
