module Mobility
  module ActiveRecord
    class Translation < ::ActiveRecord::Base
      self.abstract_class = true

      belongs_to :translatable, polymorphic: true

      validates :key, presence: true, uniqueness: { scope: [:translatable_id, :translatable_type, :locale] }
      validates :translatable, presence: true
      validates :locale, presence: true

      def __mobility_get
        value
      end

      def __mobility_set(value)
        self.value = value
      end
    end
  end
end
