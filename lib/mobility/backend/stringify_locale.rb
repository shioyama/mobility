module Mobility
  module Backend
=begin

Module which stringifies the locale passed in to read and write methods.

=end
    module StringifyLocale
      def read(locale, options = {})
        super(locale.to_s, options)
      end

      def write(locale, value, options = {})
        super(locale.to_s, value, options)
      end
    end
  end
end
