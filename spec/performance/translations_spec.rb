require "spec_helper"

describe Mobility::Translations, orm: :none do
  let!(:translations_class) do
    klass = Class.new(Mobility::Translations)
    klass.plugins do
      backend
      reader
      writer
    end
    klass
  end

  describe "initializing" do
    specify {
      expect { translations_class.new(backend: :null) }.to allocate_under(60).objects
    }
  end

  describe "including into a class" do
    specify {
      expect {
        klass = Class.new
        klass.include(translations_class.new(backend: :null))
      }.to allocate_under(170).objects
    }
  end

  describe "accessors" do
    let(:klass) do
      klass = Class.new
      klass.include(translations_class.new(:title, backend: :null))
      klass
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
