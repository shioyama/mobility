require 'spec_helper'

describe Mobility::Backend do
  describe ".method_name" do
    it "returns <attribute>_translations" do
      expect(Mobility::Backend.method_name("foo")).to eq("foo_translations")
    end
  end
end
