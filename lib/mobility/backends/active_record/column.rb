require "mobility/backends/active_record"
require "mobility/backends/column"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::Column} backend for ActiveRecord models.

You can use the +mobility:translations+ generator to create a migration adding
translatable columns to the model table with:

  rails generate mobility:translations post title:string

The generated migration will add columns +title_<locale>+ for every locale in
+I18n.available_locales+. (The generator can be run again to add new attributes
or locales.)

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

      require 'mobility/backends/active_record/column/query_methods'

      # @!group Backend Accessors
      # @!macro backend_reader
      def read(locale, _ = {})
        model.read_attribute(column(locale))
      end

      # @!group Backend Accessors
      # @!macro backend_writer
      def write(locale, value, _ = {})
        model.send(:write_attribute, column(locale), value)
      end

      setup_query_methods(QueryMethods)
    end
  end
end
