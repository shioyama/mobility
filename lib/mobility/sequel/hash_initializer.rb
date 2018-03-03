# frozen_string_literal: true

module Mobility
  module Sequel
=begin

Internal class used to initialize column value(s) by default to a hash.

=end
    class HashInitializer < Module
      def initialize(*columns)
        class_eval <<-EOM, __FILE__, __LINE__ + 1
          def initialize_set(values)
            #{columns.map { |c| "self[:#{c}] = {}" }.join(';')}
            super
          end
        EOM
      end
    end
  end
end
