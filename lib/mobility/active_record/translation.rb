module Mobility
  module ActiveRecord
    class Translation < ::ActiveRecord::Base
      self.abstract_class = true

      belongs_to :translatable, polymorphic: true

      validates :key, presence: true, uniqueness: { scope: [:translatable_id, :translatable_type, :locale] }
      validates :translatable, presence: true
      validates :locale, presence: true
    end
  end
end
