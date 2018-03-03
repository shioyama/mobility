# frozen_string_literal: true
module Mobility
  module Backend
=begin

Adds {#for} method to backend to return ORM-specific backend.

@example KeyValue backend for AR model
  class Post < ActiveRecord::Base
    # ...
  end
  Mobility::Backends::KeyValue.for(Post)
  #=> Mobility::Backends::ActiveRecord::KeyValue

=end
    module OrmDelegator
      # @param [Class] model_class Class of model
      # @return [Class] Class of backend to use for model
      def for(model_class)
        namespace = name.split('::')
        if Loaded::ActiveRecord && model_class < ::ActiveRecord::Base
          require_backend("active_record", namespace.last.underscore)
          const_get(namespace.insert(-2, "ActiveRecord").join("::"))
        elsif Loaded::Sequel && model_class < ::Sequel::Model
          require_backend("sequel", namespace.last.underscore)
          const_get(namespace.insert(-2, "Sequel").join("::"))
        else
          raise ArgumentError, "#{namespace.last} backend can only be used by ActiveRecord or Sequel models"
        end
      end

      private

      def require_backend(orm, backend)
        begin
          orm_backend = "mobility/backends/#{orm}/#{backend}"
          require orm_backend
        rescue LoadError => e
          raise unless e.message =~ /#{orm_backend}/
        end
      end
    end
  end
end
