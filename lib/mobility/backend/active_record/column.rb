module Mobility
  module Backend
=begin

Implements the {Mobility::Backend::Column} backend for ActiveRecord models.

You can use the +mobility:translations+ generator to create a migration adding
translatable columns to the model table with:

  rails generate mobility:translations post title:string

The generated migration will add columns +title_<locale>+ for every locale in
+I18n.available_locales+. (The generator can be run again to add new attributes
or locales.)

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
      include ActiveRecord
      include Column

      require 'mobility/backend/active_record/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, **_)
        model.read_attribute(column(locale))
      end

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, **_)
        model.send(:write_attribute, column(locale), value)
      end

      setup_query_methods(QueryMethods)
    end
  end
end
