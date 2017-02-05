module Mobility
  module ActiveRecord
    class ModelTranslation < ::ActiveRecord::Base
      self.abstract_class = true
      validates :locale, presence: true
    end
  end
end
