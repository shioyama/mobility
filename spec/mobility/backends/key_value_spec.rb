require "spec_helper"

describe "Mobility::Backends::KeyValue", orm: [:active_record, :sequel] do
  describe "ClassMethods" do
    let(:backend_class) do
      klass = Class.new
      klass.extend Mobility::Backends::KeyValue::ClassMethods
      klass
    end

    it "issues warning if type is not defined, and class_name and association_name are also not defined" do
      stub_const("Foo", Class.new)
      error_regex = /#{%{WARNING: In previous versions, the Mobility KeyValue backend defaulted to a}}/
      expect { backend_class.configure({}) }.to output(error_regex).to_stderr
      expect { backend_class.configure(class_name: "Foo") }.to output(error_regex).to_stderr
      expect { backend_class.configure(association_name: "foos") }.to output(error_regex).to_stderr
    end
  end
end
