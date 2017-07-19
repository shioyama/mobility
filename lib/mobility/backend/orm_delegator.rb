module Mobility
  module Backend
=begin

Adds {#for} method to backend to return ORM-specific backend.

@example KeyValue backend for AR model
  class Post < ActiveRecord::Base
    # ...
  end
  Mobility::Backend::KeyValue.for(Post)
  #=> Mobility::Backend::ActiveRecord::KeyValue

=end
    module OrmDelegator
      # @param [Class] model_class Class of model
      # @return [Class] Class of backend to use for model
      def for(model_class)
        if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
          const_get(name.split("::".freeze).insert(-2, "ActiveRecord".freeze).join("::".freeze))
        elsif Loaded::Sequel && model_class < ::Sequel::Model
          const_get(name.split("::".freeze).insert(-2, "Sequel".freeze).join("::".freeze))
        else
          raise ArgumentError, "#{name.split('::'.freeze).last} backend can only be used by ActiveRecord or Sequel models".freeze
        end
      end
    end
  end
end
