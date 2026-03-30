# frozen_string_literal: true
require "mobility/backends/active_record"
require "mobility/backends/hash_valued"

module Mobility
  module Backends
=begin

Internal class used by ActiveRecord backends backed by a database data type
(hstore, jsonb, json).

=end
    module ActiveRecord
      class DbHash
        include ActiveRecord
        include HashValued

        def read(locale, _options = nil)
          translations&.fetch(locale.to_s, nil)
        end

        def write(locale, value, _options = nil)
          translations = (model[column_name] ||= {})
          if value.nil?
            translations.delete(locale.to_s)
            nil
          else
            translations[locale.to_s] = value
          end
        end

        # @!macro backend_iterator
        def each_locale
          model[column_name]&.each_key { |l| yield l.to_sym }
        end

        def translations
          if model.new_record?
            model[column_name] ||= {}
          else
            model[column_name]
          end
        end
      end
      private_constant :DbHash
    end
  end
end
