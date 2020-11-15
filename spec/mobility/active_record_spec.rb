require "spec_helper"

return unless defined?(ActiveRecord)

require "mobility/plugins/active_record"

describe "Mobility::ActiveRecord", orm: :active_record do
  include Helpers::Plugins
  # need to require these backends to trigger loading Mobility::ActiveRecord
  require "mobility/backends/active_record/table"
  require "mobility/backends/active_record/key_value"

  pending "resolves ActiveRecord to ::ActiveRecord in model class" do
    ar_class = Class.new(ActiveRecord::Base)
    ar_class.extend Mobility

    aggregate_failures do
      expect(ar_class.instance_eval("ActiveRecord")).to eq(::ActiveRecord)
      expect(ar_class.class_eval("ActiveRecord")).to eq(::ActiveRecord)
    end
  end
end
