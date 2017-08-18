module Sequel
  module Plugins
    module Mobility
      module InstanceMethods
        def self.included(base)
          base.extend ::Mobility
        end
      end
    end
  end
end
