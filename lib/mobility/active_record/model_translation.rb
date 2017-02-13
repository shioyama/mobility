module Mobility
  module ActiveRecord
=begin

Subclassed dynamically to generate translation class in
{Backend::ActiveRecord::Table} backend.

=end
    class ModelTranslation < ::ActiveRecord::Base
      self.abstract_class = true
      validates :locale, presence: true
    end
  end
end
