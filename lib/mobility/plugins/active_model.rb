require_relative "./active_model/dirty"
require_relative "./active_model/cache"

module Mobility
  module Plugins
=begin

Plugin for ActiveModel models. In practice, this is simply a wrapper to include
a few plugins which apply to models which include ActiveModel::Dirty but are
not ActiveRecord models.

=end
    module ActiveModel
      extend Plugin

      depends_on :active_model_dirty
      depends_on :active_model_cache
      depends_on :backend, include: :before
    end

    register_plugin(:active_model, ActiveModel)
  end
end
