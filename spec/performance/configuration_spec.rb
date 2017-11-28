require "spec_helper"

describe Mobility::Configuration do
  context "when initializing" do
    specify {
      expect { described_class.new }.to allocate_under(8).objects
    }
  end
end
