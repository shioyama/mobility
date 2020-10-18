# frozen_string_literal: true
require "mobility/pluggable"

module Mobility
=begin

Module containing translation accessor methods and other methods for accessing
translations.

Normally this class will be created by calling
{Mobility::Translates#translates}, which is a class method on any model that
extends {Mobility}, but it can also be used independent of that macro.

==Including Translations in a Class

Since {Translations} is a subclass of +Module+, including an instance of it is
like including a module. Options passed to the initializer are passed to
plugins (if those plugins have been enabled).

We can first enable plugins by subclassing `Mobility::Translations`, and
calling +plugins+ to enable any plugins we want to use. We want reader and
writer methods for accessing translations, so we enable those plugins:

  class Translations < Mobility::Translations
    plugins do
      reader
      writer
    end
  end

Both `reader` and `writer` depend on the `backend` plugin, so this is also enabled.

Then create an instance like this:

  Translations.new("title", backend: :my_backend)

This will generate an anonymous module that behaves approximately like this:

  Module.new do
    # From Mobility::Plugins::Backend module
    #
    def mobility_backends
      # Returns a memoized hash with attribute name keys and backend instance
      # values.  When a key is fetched from the hash, the hash calls
      # +self.class.mobility_backend_class(name)+ (where +name+ is the
      # attribute name) to get the backend class, then instantiate it (passing
      # the model instance and attribute name to its initializer) and return it.
    end

    # From Mobility::Plugins::Reader module
    #
    def title(locale: Mobility.locale)
      mobility_backends[:title].read(locale)
    end

    def title?(locale: Mobility.locale)
      mobility_backends[:title].read(locale).present?
    end

    # From Mobility::Plugins::Writer module
    def title=(value, locale: Mobility.locale)
      mobility_backends[:title].write(locale, value)
    end
  end

Including this module into a model class will thus add the backends method and
reader and writer methods for accessing translations. Other plugins (e.g.
fallbacks, cache) modify the result returned by the backend, by hooking into
the +included+ callback method on the module, see {Mobility::Plugin} for
details.

==Setting up the Model Class

Accessor methods alone are of limited use without a hook to actually modify the
model class. This hook is provided by the {Backend::Setup#setup_model} method,
which is added to every backend class when it includes the {Backend} module.

Assuming the backend has defined a setup block by calling +setup+, this block
will be called when {Translations} is {#included} in the model class, passed
attributes and options defined when the backend was defined on the model class.
This allows a backend to do things like (for example) define associations on a
model class required by the backend, as happens in the {Backends::KeyValue} and
{Backends::Table} backends.

Since setup blocks are evaluated on the model class, it is possible that
backends can conflict (for example, overwriting previously defined methods).
Care should be taken to avoid defining methods on the model class, or where
necessary, ensure that names are defined in such a way as to avoid conflicts
with other backends.

=end
  class Translations < Pluggable
    include ::Mobility::Plugins.load_plugin(:attributes)
  end
end
