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
  #=> Mobility::Backends::ActionText::RichText::Translation

=end
    class ActionText < ActiveRecord::KeyValue
      class << self
        # @!group Backend Configuration
        # @option (see Mobility::Backends::KeyValue::ClassMethods#configure)
        def configure(options)
          options[:association_name] ||= "rich_text_translations"
          options[:class_name]       ||= Translation
          options[:key_column]       ||= :name
          options[:value_column]     ||= :body
          options[:translatable]     ||= :record
          options[:table_alias_affix] = "#{model_class}_%s_#{options[:association_name]}"
          super
        end
        # @!endgroup
      end

      # FIXME: replace:
      #   - `:translatable` with `options[:translatable]`
      #   - `:key` with `options[:key_column]`
      class Translation < ::ActiveRecord::Base
        self.table_name = "action_text_rich_texts"

        belongs_to :record, polymorphic: true, touch: true

        validates :name, presence: true, uniqueness: { scope: [:record_id, :record_type, :locale], case_sensitive: true }
        validates :record, presence: true
        validates :locale, presence: true
      end
    end

    register_backend(:active_record_action_text, ActionText)
  end
end
