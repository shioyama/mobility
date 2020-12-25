# frozen-string-literal: true
require "mobility/backends/active_record/key_value"

module Mobility
  module Backends
=begin

Implements the {Mobility::Backends::KeyValue} backend for ActionText.

@example
  class Post < ApplicationRecord
    extend Mobility
    translates :content, backend: :action_text
    has_rich_text :content
  end

  post = Post.create(content: "<h1>My text is rich</h1>")
  post.rich_text_translations
  #=> #<ActionText::RichText::ActiveRecord_Associations_CollectionProxy ... >
  post.rich_text_translations.first.to_s
  #=> "<div class=\"trix-content\">\n  <h1>My text is rich</h1>\n</div>\n"
  post.content
  #=> "<div class=\"trix-content\">\n  <h1>My text is rich</h1>\n</div>\n"
  post.rich_text_translations.first.class
  #=> ActionText::RichText

=end
    class ActiveRecord::ActionText < ActiveRecord::KeyValue
      class << self
        # @!group Backend Configuration
        # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
        def configure(options)
          options[:association_name] ||= "rich_text_translations"
          options[:class_name]       ||= ::ActionText::RichText
          options[:key_column]       ||= :name
          options[:value_column]     ||= :body
          options[:translatable]     ||= :record
          options[:table_alias_affix] = "#{model_class}_%s_#{options[:association_name]}"
          super
        end
        # @!endgroup
      end
    end

    register_backend(:active_record_action_text, ActiveRecord::ActionText)
  end
end
