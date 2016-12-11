module Mobility
  module Backend
    module OrmDelegator
      def for(model_class)
        if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
          const_get(name.split("::").insert(-2, "ActiveRecord").join("::"))
        elsif Loaded::Sequel && model_class < ::Sequel::Model
          const_get(name.split("::").insert(-2, "Sequel").join("::"))
        else
          raise ArgumentError, "#{name.split('::').last} backend can only be used by ActiveRecord or Sequel models"
        end
      end

      def self.included(base)
        base.extend(self)
      end
    end
  end
end
