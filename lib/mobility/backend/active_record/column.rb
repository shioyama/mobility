module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Column} backend for ActiveRecord models.

@note This backend disables the +locale_accessors+ option, which would
  otherwise interfere with column methods.

@example
  class Post < ActiveRecord::Base
    translates :title, backend: :column
  end

  Mobility.locale = :en
  post = Post.create(title: "foo")
  post.title
  #=> "foo"
  post.title_en
  #=> "foo"
=end
    class ActiveRecord::Column
      include Backend
      include Mobility::Backend::Column

      autoload :QueryMethods, 'mobility/backend/active_record/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      # @!method read(locale, **options)

      # @!group Backend Accessors
      # @!macro backend_writer
      # @!method write(locale, value, **options)

      # @!group Backend Configuration
      def self.configure!(options)
        options[:locale_accessors] = false
      end
      # @!endgroup

      setup do |attributes, options|
        mod = Module.new do
          define_method :i18n do
            @mobility_scope ||= super().extending(QueryMethods.new(attributes, options))
          end
        end
        extend mod
      end
    end
  end
end
