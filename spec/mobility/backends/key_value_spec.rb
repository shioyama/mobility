require "spec_helper"

describe "Mobility::Backends::KeyValue", orm: [:active_record, :sequel] do
  describe "ClassMethods" do
    let(:backend_class) do
      klass = Class.new
      klass.extend Mobility::Backends::KeyValue::ClassMethods
      klass
    end

    it "raises ArgumentError if type is not defined, and class_name and association_name are also not defined" do
      stub_const("Foo", Class.new)
      error_msg = /KeyValue backend requires an explicit type option/
      expect { backend_class.configure({}) }.to raise_error(ArgumentError, error_msg)
      expect { backend_class.configure(class_name: "Foo") }.to raise_error(ArgumentError, error_msg)
      expect { backend_class.configure(association_name: "foos") }.to raise_error(ArgumentError, error_msg)
    end
  end
end
