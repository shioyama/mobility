module Mobility
=begin

Plugins allow modular customization of backends independent of the backend
itself. They are enabled through the {Configuration.plugins} configuration
setting, which takes an array of symbols corresponding to plugin names. The
order of these names is important since it determines the order in which
plugins will be applied.

So if our {Configuration.plugins} is an array +[:foo]+, and we call
`translates` on our model, +Post+, like this:

  class Post
    translates :title, foo: true
  end

Then the +Foo+ plugin will be applied with the option value +true+. Applying a
module calls a class method, +apply+ (in this case +Foo.apply+), which takes
two arguments:

- an instance of the {Attributes} class, +attributes+, from which the backend
  can configure the backend class (+attributes.backend_class+) and the model
  (+attributes.model_class+), and the +attributes+ module itself (which
  will be included into the backend).
- the value of the +option+ passed into the model with +translates+ (in this
  case, +true+).

Typically, the plugin will include a module into either
+attributes.backend_class+ or +attributes+ itself, configured according to the
option value. For examples, see classes under the {Mobility::Plugins} namespace.

=end
  module Plugins
    autoload :ActiveModel,          'mobility/plugins/active_model'
    autoload :ActiveRecord,         'mobility/plugins/active_record'
    autoload :Cache,                'mobility/plugins/cache'
    autoload :Default,              'mobility/plugins/default'
    autoload :Dirty,                'mobility/plugins/dirty'
    autoload :Fallbacks,            'mobility/plugins/fallbacks'
    autoload :FallthroughAccessors, 'mobility/plugins/fallthrough_accessors'
    autoload :LocaleAccessors,      'mobility/plugins/locale_accessors'
    autoload :Presence,             'mobility/plugins/presence'
    autoload :Sequel,               'mobility/plugins/sequel'
  end
end
