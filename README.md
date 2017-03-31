Mobility
========

[![Gem Version](https://badge.fury.io/rb/mobility.svg)][gem]
[![Build Status](https://travis-ci.org/shioyama/mobility.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/shioyama/mobility.svg)][gemnasium]
[![Code Climate](https://codeclimate.com/github/shioyama/mobility/badges/gpa.svg)][codeclimate]

[gem]: https://rubygems.org/gems/mobility
[travis]: https://travis-ci.org/shioyama/mobility
[gemnasium]: https://gemnasium.com/shioyama/mobility
[codeclimate]: https://codeclimate.com/github/shioyama/mobility
[docs]: http://www.rubydoc.info/gems/mobility
[wiki]: https://github.com/shioyama/mobility/wiki

Mobility is a gem for storing and retrieving translations as attributes on a
class. These translations could be the content of blog posts, captions on
images, tags on bookmarks, or anything else you might want to store in
different languages.

Storage of translations is handled by customizable "backends" which encapsulate
different storage strategies. The default, preferred way to store translations
is to put them all in a set of two shared tables, but many alternatives are
also supported, including translatable columns (like
[Traco](https://github.com/barsoom/traco)) and translation tables (like
[Globalize](https://github.com/globalize/globalize)), as well as
database-specific storage solutions such as
[jsonb](https://www.postgresql.org/docs/current/static/datatype-json.html ) and
[Hstore](https://www.postgresql.org/docs/current/static/hstore.html) (for
PostgreSQL).

Mobility is a cross-platform solution, currently supporting both
[ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Base.html)
and [Sequel](http://sequel.jeremyevans.net/) ORM, with support for other
platforms planned.

For a detailed introduction to Mobility, see [Translating with
Mobility](http://dejimata.com/2017/3/3/translating-with-mobility). See also the
[Roadmap](https://github.com/shioyama/mobility/wiki/Roadmap) for what's in the
works for future releases.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'mobility', '~> 0.1.11'
```

To translate attributes on a model, include (or extend) `Mobility`, then call
`translates` passing in one or more attributes as well as a hash of options.

### ActiveRecord (Rails)

Requirements:
- ActiveRecord >= 5.0

(Support for some backends is also supported with ActiveRecord/Rails 4.2, see
the [active_record-4.2
branch](https://github.com/shioyama/mobility/tree/active_record_4.2).)

If using Mobility in a Rails project, you can run the generator to create an
initializer and a migration to create shared translation tables for the
default `KeyValue` backend:

```
rails generate mobility:install
```

(If you do not plan to use the default backend, you may want to use
the `--without_tables` option here to skip the migration generation.)

The generator will create an initializer file `config/initializers/mobility.rb`
with the lines:

```ruby
Mobility.configure do |config|
  config.default_backend = :key_value
  config.accessor_method = :translates
end
```

To use a different default backend, set `default_backend` to another value (see
possibilities [below](#backends)). Other configuration options are
described in the [API
docs](http://www.rubydoc.info/gems/mobility/Mobility/Configuration).

See [Getting Started](#quickstart) to get started translating your models.

### Sequel

Requirements:
- Sequel >= 4.0

You can include `Mobility` just like in ActiveRecord, or you can use the
`mobility` plugin, which does the same thing:

```ruby
class Post < ::Sequel::Model
  plugin :mobility
  translates :title,   type: :string
  translates :content, type: :text
end
```

Otherwise everything is (almost) identical to AR, with the exception that there
is no equivalent to a Rails generator (so you will need to create the migration
for any translation table(s) yourself, using Rails generators as a reference).

The models in examples below all inherit from `ApplicationRecord`, but
everything works exactly the same if the parent class is `Sequel::Model`.

Usage
-----

### <a name="quickstart"></a>Getting Started

Once the install generator has been run to generate translation tables, using
Mobility is as easy as adding a few lines to any class you want to translate:

```ruby
class Word < ApplicationRecord
  include Mobility
  translates :name,    type: :string
  translates :meaning, type: :text
end
```

You now have translated attributes `name` (as a string column) and `meaning`
(as a text column) on the model `Word`. You can set their values like you
would any other attribute:


```ruby
word = Word.new
word.name = "mobility"
word.meaning = "(noun): quality of being changeable, adaptable or versatile"
word.name
#=> "mobility"
word.meaning
#=> "(noun): quality of being changeable, adaptable or versatile"
word.save
word = Word.first
word.name
#=> "mobility"
word.meaning
#=> "(noun): quality of being changeable, adaptable or versatile"
```

Presence methods are also supported:

```ruby
word.name?
#=> true
word.name = nil
word.name?
#=> false
word.name = ""
word.name?
#=> false
```

What's different here is that the value of these attributes changes with the
value of `I18n.locale`:

```ruby
I18n.locale = :ja
word.name
#=> nil
word.meaning
#=> nil
```

The `name` and `meaning` of this word are not defined in any locale except
English. Let's define them in Japanese and save the model:

```ruby
word.name = "モビリティ"
word.meaning = "(名詞):動きやすさ、可動性"
word.name
#=> "モビリティ"
word.meaning
#=> "(名詞):動きやすさ、可動性"
word.save
```

Now our word has names and meanings in two different languages:

```ruby
word = Word.first
I18n.locale = :en
word.name
#=> "mobility"
word.meaning
#=> "(noun): quality of being changeable, adaptable or versatile"
I18n.locale = :ja
word.name
#=> "モビリティ"
word.meaning
#=> "(名詞):動きやすさ、可動性"
```

Internally, Mobility is mapping the values in different locales to storage
locations, usually database columns. By default these values are stored as keys
(attribute names) and values (attribute translations) on a set of translation
tables, one for strings and one for text columns, but this can be easily
changed and/or customized (see the [Backends](#backends) section below).

### Getting and Setting Translations

The easiest way to get or set a translation is to use the getter and setter
methods described above (`word.name` and `word.name=`), but you may want to
access the value of an attribute in a specific locale, independent of the
current value of `I18n.locale` (or `Mobility.locale`). There are a few ways to
do this.

The first way is to define locale-specific methods, one for each locale you
want to access directly on a given attribute. These are called "locale
accessors" in Mobility, and they can be defined by passing a `locale_accessors`
option when defining translated attributes on the model class:

```ruby
class Word < ApplicationRecord
  include Mobility
  translates :name, type: :string, locale_accessors: [:en, :ja]
end
```

Since we have enabled locale accessors for English and Japanese, we can access
translations for these locales with `name_en` and `name_ja`:

```ruby
word.name_en
#=> "mobility"
word.name_ja
#=> "モビリティ"
word.name_en = "foo"
word.name
#=> "foo"
```

Other locales, however, will not work:

```ruby
word.name_ru
#=> NoMethodError: undefined method `name_ru' for #<Word id: ... >
```

To generate methods for all locales in `I18n.available_locales` (at the time
the model is first loaded), use `locale_accessors: true`.

An alternative to using the `locale_accessors` option is to use the
`fallthrough_accessors` option, with `fallthrough_accessors: true`. This uses
Ruby's [`method_missing`](http://apidock.com/ruby/BasicObject/method_missing)
method to implicitly define the same methods as above, but supporting any
locale without any method definitions. (Locale accessors and fallthrough
locales can be used together without conflict, with locale accessors taking
precedence if defined for a given locale.)

For example, if we define `Word` this way:

```ruby
class Word < ApplicationRecord
  include Mobility
  translates :name, type: :string, fallthrough_accessors: true
end
```

... then we can access any locale we want, without specifying them upfront:

```ruby
word = Word.new
word.name_fr = "mobilité"
word.name_fr
#=> "mobilité"
word.name_ja = "モビリティ"
word.name_ja
#=> "モビリティ"
```

(Note however that Mobility will complain if you have
`I18n.enforce_available_locales` set to `true` and you try accessing a locale
not present in `I18n.available_locales`; set it to `false` if you want to allow
*any* locale.)

Another way to fetch values in a locale is to pass the `locale` option to the
getter method, like this:

```ruby
word.name(locale: :en)
#=> "mobility"
word.name(locale: :fr)
#=> "mobilité"
```

You can also *set* the value of an attribute this way; however, since the
`word.name = <value>` syntax does not accept any options, the only way to do this is to
use `send` (this is included mostly for consistency):

```ruby
word.send(:name=, "mobiliteit", locale: :nl)
word.name_nl
#=> "mobiliteit"
```

Yet another way to get and set translated attributes is to call `read` and
`write` on the storage backend, which can be accessed using the method
`<attribute>_backend`. Without worrying too much about the details of
how this works for now, the syntax for doing this is simple:

```ruby
word.name_backend.read(:en)
#=> "mobility"
word.name_backend.read(:nl)
#=> "mobiliteit"
word.name_backend.write(:en, "foo")
word.name_backend.read(:en)
#=> "foo"
```

Internally, all methods for accessing translated attributes ultimately end up
reading and writing from the backend instance this way.

### Setting the Locale

It may not always be desirable to use `I18n.locale` to set the locale for
content translations. For example, a user whose interface is in English
(`I18n.locale` is `:en`) may want to see content in Japanese. If you use
`I18n.locale` exclusively for the locale, you will have a hard time showing
stored translations in one language while showing the interface in another
language.

For these cases, Mobility also has its own locale, which defaults to
`I18n.locale` but can be set independently:

```ruby
I18n.locale = :en
Mobility.locale              #=> :en
Mobility.locale = :fr
Mobility.locale              #=> :fr
I18n.locale                  #=> :en
```

To set the Mobility locale in a block, you can use `Mobility.with_locale` (like
`I18n.with_locale`):

```ruby
Mobility.locale = :en
Mobility.with_locale(:ja) do
  Mobility.locale            #=> :ja
end
Mobility.locale              #=> :en
```

Mobility uses [RequestStore](https://github.com/steveklabnik/request_store) to
reset these global variables after every request, so you don't need to worry
about thread safety. If you're not using Rails, consult RequestStore's
[README](https://github.com/steveklabnik/request_store#no-rails-no-problem) for
details on how to configure it for your use case.

### <a name="fallbacks"></a>Fallbacks

Mobility offers basic support for translation fallbacks. To enable fallbacks,
pass a hash with fallbacks for each locale as an option when defining
translated attributes on a class:

```ruby
class Word < ApplicationRecord
  include Mobility
  translates :name,    type: :string, fallbacks: { de: :ja, fr: :ja }
  translates :meaning, type: :text,   fallbacks: { de: :ja, fr: :ja }
end
```

Internally, Mobility assigns the fallbacks hash to an instance of
`I18n::Locale::Fallbacks.new` (this can be customized by setting the
`default_fallbacks` configuration option, see the [API documentation on
configuration](http://www.rubydoc.info/gems/mobility/Mobility/Configuration)).

By setting fallbacks for German and French to Japanese, values will fall
through to the Japanese value if none is present for either of these locales,
but not for other locales:

```ruby
Mobility.locale = :ja
word = Word.create(name: "モビリティ", meaning: "(名詞):動きやすさ、可動性")
word.name(locale: :de)
#=> "モビリティ"
word.meaning(locale: :de)
#=> "(名詞):動きやすさ、可動性"
word.name(locale: :fr)
#=> "モビリティ"
word.meaning(locale: :fr)
#=> "(名詞):動きやすさ、可動性"
word.name(locale: :ru)
#=> nil
word.meaning(locale: :ru)
#=> nil
```

You can optionally disable fallbacks to get the real value for a given locale
(for example, to check if a value in a particular locale is set or not) by
passing `fallback: false` (*singular*, not plural) to the getter method:

```ruby
word.meaning(locale: :de, fallback: false)
#=> nil
word.meaning(locale: :fr, fallback: false)
#=> nil
word.meaning(locale: :ja, fallback: false)
#=> "(名詞):動きやすさ、可動性"
```

You can also set the fallback locales for a single read by passing one or more
locales:

```ruby
Mobility.with_locale(:fr) do
  word.meaning = "(nf): aptitude à bouger, à se déplacer, à changer, à évoluer"
end
word.save
word.meaning(locale: :de, fallback: false)
#=> nil
word.meaning(locale: :de, fallback: :fr)
#=> "(nf): aptitude à bouger, à se déplacer, à changer, à évoluer"
word.meaning(locale: :de, fallback: [:ja, :fr])
#=> "(名詞):動きやすさ、可動性"
```

For more details, see the [API documentation on
fallbacks](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Fallbacks)
and [this article on I18n
fallbacks](https://github.com/svenfuchs/i18n/wiki/Fallbacks).

### <a name="dirty"></a>Dirty Tracking

Dirty tracking (tracking of changed attributes) can be enabled for models which
support it. Currently this is models which include
[ActiveModel::Dirty](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html)
(like `ActiveRecord::Base`) and Sequel models (through the
[dirty](http://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/Dirty.html)
plugin).

Enabling dirty tracking is as simple as sending the `dirty: true` option when
defining a translated attribute. The way dirty tracking works is somewhat
dependent on the model class (ActiveModel or Sequel); we will describe the
ActiveModel implementation here.

First, enable dirty tracking (note that this is a persisted AR model, although
dirty tracking is not specific to AR and works for non-persisted models as well):

```ruby
class Post < ApplicationRecord
  include Mobility
  translates :title, type: :string, dirty: true
end
```

Let's assume we start with a post with a title in English and Japanese:

```ruby
post = Post.create(title: "Introducing Mobility")
Mobility.with_locale(:ja) { post.title = "モビリティの紹介" }
post.save
```

Now let's change the title:

```ruby
post = Post.first
post.title                      #=> "Introducing Mobility"
post.title = "a new title"
Mobility.with_locale(:ja) do
  post.title                    #=> "モビリティの紹介"
  post.title = "新しいタイトル"
  post.title                    #=> "新しいタイトル"
end
```

Now you can use dirty methods as you would any other (untranslated) attribute:

```ruby
post.title_was
#=> "Introducing Mobility"
Mobility.locale = :ja
post.title_was
#=> "モビリティの紹介"
post.changed
["title_en", "title_ja"]
post.save
```

You can also access `previous_changes`:

```ruby
post.previous_changes
#=>
{
  "title_en" =>
    [
      "Introducing Mobility",
      "a new title"
    ],
  "title_ja" =>
    [
      "モビリティの紹介",
      "新しいタイトル"
    ]
}
```

Notice that Mobility uses locale suffixes to indicate which locale has changed;
dirty tracking is implemented this way to ensure that it is clear what
has changed in which locale, avoiding any possible ambiguity.

For more details, see the [API documentation on dirty
tracking](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Dirty).

### Cache

The Mobility cache caches localized values that have been fetched once so they
can be quickly retrieved again. The cache is enabled by default and should
generally only be disabled when debugging; this can be done by passing `cache:
false` when defining an attribute, like this:

```ruby
class Word < ApplicationRecord
  include Mobility
  translates :name, type: :string, cache: false
end
```

The cache is normally just a hash with locale keys and string (translation)
values, but some backends (e.g. KeyValue and Table backends) have slightly more
complex implementations.

### <a name="querying"></a>Querying

Database-backed Mobility backends also optionally support querying through
`where` and other query methods (`not` and `find_by` for ActiveRecord models,
`except` for Sequel models, etc). To query on these attributes, use the `i18n`
class method, which will return a model relation extended with
Mobility-specific query method overrides.

So assuming a model:

```ruby
class Post < ApplicationRecord
  include Mobility
  translates :title,   type: :string
  translates :content, type: :text
end
```

... we can query for posts with title "foo" and content "bar" just as we would
query on untranslated attributes, and Mobility will convert the queries to
whatever the backend requires to actually return the correct results:

```ruby
Post.i18n.find_by(title: "foo", content: "bar")
```

results in the SQL:

```sql
SELECT "posts".* FROM "posts"
INNER JOIN "mobility_string_translations" "title_mobility_string_translations"
  ON "title_mobility_string_translations"."key" = 'title'
  AND "title_mobility_string_translations"."locale" = 'en'
  AND "title_mobility_string_translations"."translatable_type" = 'Post'
  AND "title_mobility_string_translations"."translatable_id" = "posts"."id"
INNER JOIN "mobility_text_translations" "content_mobility_text_translations"
  ON "content_mobility_text_translations"."key" = 'content'
  AND "content_mobility_text_translations"."locale" = 'en'
  AND "content_mobility_text_translations"."translatable_type" = 'Post'
  AND "content_mobility_text_translations"."translatable_id" = "posts"."id"
WHERE "content_mobility_text_translations"."value" = 'bar'
  AND "title_mobility_string_translations"."value" = 'foo'
```

As can be seen in the query above, behind the scenes Mobility joins two tables,
one with string translations and one with text translations, and aliases the
joins for each attribute so as to match the particular values passed in to the
query. Details of how this is done can be found in the [API documentation for
AR query
methods](http://www.rubydoc.info/gems/mobility/Mobility/Backend/ActiveRecord/KeyValue/QueryMethods).

If you would prefer to avoid the `i18n` scope everywhere, define it as a
default scope on your model:

```ruby
class Post < ApplicationRecord
  include Mobility
  translates :title,   type: :string
  translates :content, type: :text
  default_scope { i18n }
end
```

Now translated attributes can be queried just like normal attributes:

```ruby
Post.find_by(title: "Introducing Mobility")
#=> finds post with English title "Introducing Mobility"
```

<a name="backends"></a>Backends
--------

Mobility supports different storage strategies, called "backends". The default
backend is the `KeyValue` backend, which stores translations in two tables, by
default named `mobility_text_translations` and `mobility_string_translations`.

You can set the default backend to a different value in the global
configuration, or you can set it explicitly when defining a translated
attribute, like this:

```ruby
class Word < ApplicationRecord
  translates :name, backend: :table
end
```

This would set the `name` attribute to use the `Table` backend (see below).
The `type` option (`type: :string` or `type: :text`) is missing here because
this is an option specific to the KeyValue backend (specifying which shared
table to store translations on). Backends have their own specific options; see
the API documentation for which options are available for each.

Everything else described above (fallbacks, dirty tracking, locale accessors,
caching, querying, etc) is the same regardless of which backend you use.

### Table Backend (like Globalize)

The `Table` backend stores translations as columns on a model-specific table. If
your model uses the table `posts`, then by default this backend will store an
attribute `title` on a table `post_translations`, and join the table to
retrieve the translated value.

To use the table backend on a model, you will need to first create a
translation table for the model, which (with Rails) you can do using the
`mobility:translations` generator:

```
rails generate mobility:translations post title:string content:text
```

This will generate the `post_translations` table with columns `title` and
`content`, and all other necessary columns and indices. For more details see
the API documentation on the [`Mobility::Backend::Table`
class](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Table).

### Column Backend (like Traco)

The `Column` backend stores translations as columns with locale suffixes on
the model table. For an attribute `title`, these would be of the form
`title_en`, `title_fr`, etc.

Use the `mobility:translations` generator to add columns for locales in
`I18n.available_locales` to your model:

```
rails generate mobility:translations post title:string content:text
```

For more details, see the API documentation on the [`Mobility::Backend::Column`
class](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Column).

### PostgreSQL-specific Backends

Mobility also supports jsonb and Hstore storage options, if you are using
PostgreSQL as your database. To use this option, create column(s) on the model
table for each translated attribute, and set your backend to `:jsonb` or
`:hstore`. Other details are covered in the API documentation
([`Mobility::Backend::Jsonb`](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Jsonb)
and
[`Mobility::Backend::Hstore`](http://www.rubydoc.info/gems/mobility/Mobility/Backend/Hstore)).

Development
-----------

### Custom Backends

Although Mobility is primarily oriented toward storing ActiveRecord model
translations, it can potentially be used to handle storing translations in
other formats. In particular, the features mentioned above (locale accessors,
caching, fallbacks, dirty tracking to some degree) are not specific to database
storage.

To use a custom backend, simply pass the name of a class which includes
`Mobility::Backend` to `translates`:

```ruby
class MyBackend
  include Mobility::Backend
  # ...
end

class MyClass
  include Mobility
  translates :foo, backend: MyBackend
end
```

For details on how to define a backend class, see the [API documentation on the
`Mobility::Backend`
module](http://www.rubydoc.info/gems/mobility/Mobility/Backend).

### Testing Backends

All included backends are tested against a suite of shared specs which ensure
they conform to the same expected behaviour. These examples can be found in:

- `spec/support/shared_examples/accessor_examples.rb` (minimal specs testing
  translation setting/getting)
- `spec/support/shared_examples/querying_examples.rb` (specs for
  [querying](#querying))
- `spec/support/shared_examples/serialization_examples.rb` (specialized specs
  for backends which store translations as a Hash: `serialized`, `hstore` and
  `jsonb` backends)

A minimal test can simply define a model class and use helpers defined in
`spec/support/helpers.rb` to run these examples, by extending either
`Helpers::ActiveRecord` or `Helpers::Sequel`:

```ruby
describe MyBackend do
  extend Helpers::ActiveRecord

  before do
    stub_const 'MyPost', Class.new(ActiveRecord::Base)
    MyPost.include Mobility
    MyPost.translates :title, :content, backend: MyBackend
  end

  include_accessor_examples 'MyPost'
  include_querying_examples 'MyPost'
  # ...
end
```

Shared examples expect the model class to have translated attributes `title`
and `content`, and an untranslated boolean column `published`. These defaults
can be changed, see the shared examples for details.

Backends are also each tested against specialized specs targeted at their
particular implementations.

More Information
----------------

- [Github repository](https://www.github.com/shioyama/mobility)
- [API documentation][docs]
- [Wiki][wiki]

License
-------

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
