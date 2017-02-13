module Mobility
  module Backend
=begin

Stores translated attribute as a column on the model table.

To use this backend, ensure that the model table has columns named
+<attribute>_<locale>+ for every locale in +I18n.available_locales+.

==Backend Options

There are no options for this backend. Also, the +locale_accessors+ option will
be ignored if set, since it would cause a conflict with column accessors.

@see Mobility::Backend::ActiveRecord::Column
@see Mobility::Backend::Sequel::Column

=end
    module Column
      include OrmDelegator

      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, **options)
        model.send(column(locale))
      end

      # @!macro backend_writer
      def write(locale, value, **options)
        model.send("#{column(locale)}=", value)
      end
      # @!endgroup

      # Returns name of column where translated attribute is stored
      # @param [Symbol] locale
      # @return [String]
      def column(locale = Mobility.locale)
        Column.column_name_for(attribute, locale)
      end

      # Returns name of column where translated attribute is stored
      # @param [String] attribute
      # @param [Symbol] locale
      # @return [String]
      def self.column_name_for(attribute, locale = Mobility.locale)
        normalized_locale = locale.to_s.downcase.sub("-", "_")
        "#{attribute}_#{normalized_locale}".to_sym
      end
    end
  end
end
