module Sequel
  module Plugins
    module Mobility
      module InstanceMethods
        def self.included(base)
          base.include(::Mobility)
        end
      end
    end
  end
end
