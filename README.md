[gem]: https://rubygems.org/gems/mobility
[travis]: https://travis-ci.org/shioyama/mobility

# Mobility

[![Gem Version](https://badge.fury.io/rb/mobility.svg)][gem]
[![Build Status](https://travis-ci.org/shioyama/mobility.svg?branch=master)][travis]

Mobility is a gem for storing and retrieving localized data through attributes
on a class. A variety of different storage strategies are supported through
pluggable, customizable "backends" implemented via a common interface.

Out of the box, Mobility supports:

- translations as localized columns on the model table (like [Traco](https://github.com/barsoom/traco))
- translations on a model-specific table (like [Globalize](https://github.com/globalize/globalize))
- translations as values on globally shared key-value tables (the default, see [below](#backend))
- translations as values of a hash serialized on a text column of the model table (like [Multilang](https://github.com/artworklv/multilang))
- translations as values of a hash stored as an hstore column on a Postgres model table (like [Trasto](https://github.com/yabawock/trasto), [Multilang-hstore](https://github.com/bithavoc/multilang-hstore), [hstore_translate](https://github.com/Leadformance/hstore_translate), etc.)
- translations as values of a hash stored as a jsonb column on a Postgres model table (like [json_translate](https://github.com/cfabianski/json_translate))

Each backend is implemented for both
[ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) and
[Sequel](http://sequel.jeremyevans.net/) ORM, including a common interface for
[querying](#querying) the database on translated attributes using extended
scopes/datasets. Mobility is however flexible enough to support any storage
strategy, including ones not backed by a database.

All backends can optionally enable any of a set of common, ORM-independent
features, including:

- a [cache](#cache) to improve read/write performance (included by default)
- translation [fallbacks](#fallbacks), in case a translation is missing in a
  given locale
- (for classes that support it) [dirty](#dirty) tracking of changed attributes
  (`ActiveModel::Dirty` in Rails)
- [locale-specific accessors](#locale-accessors) for translated attributes, of
  the form `<attribute>_<locale>` (similar to
  [globalize-accessors](https://github.com/globalize/globalize-accessors))

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mobility', '~> 0.1.2'
```

To translate attributes on a model, you must include (or extend) `Mobility`,
then call `translates` passing in one or more attributes as well as a hash of
options, including the backend to use. (See [Defining Backend
Attributes](#attributes) below.)

### ActiveRecord (Rails)

Requirements:
- ActiveRecord >= 5.0

(Support for some backends is also supported with ActiveRecord/Rails 4.2, see
the [active_record-4.2
branch](https://github.com/shioyama/mobility/tree/active_record_4.2).)

If using Mobility in a Rails project, you can run the generator to create an
initializer and (optionally) a migration to create shared tables for the
default key-value backend:

```
rails generate mobility:install
```

To skip the migration (if you do not plan to use the default `KeyValue`
backend), use the `--without_tables` option:

```
rails generate mobility:install --without_tables
```

The generator will create an initializer file `config/initializers/mobility.rb`
with the line:

```
Mobility.config.default_backend = :key_value
```

To set a different default backend, set `default_backend` to another value (see
possibilities [below](#backend)). Other configuration options can be set using the
`configure` method, see: {Mobility::Configuration} for details.

To get started quickly, run the generator with tables, and add the following to
a class to add translated attributes:

```ruby
class Post < ActiveRecord::Base
  translates :title,   type: :string
  translates :content, type: :content
end
```

You now have translated attributes `title` and `content` on the model:

```ruby
I18n.locale = :en
post = Post.create(title: "foo")
post.title                         #=> "Mobility"
I18n.locale = :ja
post.title                         #=> nil
post.title = "モビリティ"
post.save
post.title                         #=> "モビリティ"
I18n.locale = :en
post.title                         #=> "Mobility"
```

Congratulations! Now have a look at the [Usage](#usage) section to see what
else Mobility can do.

### Sequel

Requirements:
- Sequel >= 4.0

Essentially identical to ActiveRecord, with the exception that there is no
equivalent to a Rails generator (so you will need to create the migration for
any translation table(s) yourself, see the API docs for details).

## Usage

### <a name="attributes"></a>Defining Backend Attributes

In order to use Mobility on a class, you will need to `extend` the {Mobility}
module and call `translates`, passing in one or more attribute names as well as
a hash of options.

The options hash is used to generate the backend, and has several reserved keys:

- **`backend`** (Symbol or Class)<br>
  The backend to use (defaults to the value of `Mobility.default_backend`). If
  its value is a symbol it will be converted to CamelCase and appended to the
  `Mobility::Backend` module name to get the backend class (so `key_value` will
  be converted to {Mobility::Backend::KeyValue}). See the list of [backends](#backend).
- **`cache`** (Boolean)<br>
  Whether to use a [cache](#cache).
- **`fallbacks`** (Boolean or Hash)<br>
  Enable [fallbacks](#fallbacks), and optionally configure them.
- **`dirty`** (Boolean)<br>
  Whether to enable [dirty tracking](#dirty).
- **`accessor_locales`** (Boolean or Array)<br>
  Enable [locale accessors](#locale_accessors) and optionally configure them.

In addition to these, each backend may have specific configuration options. For
example, the default key-value backend, which stores attributes and their
translations as key/value pairs on shared tables, has a `type` option which
specifies which type of column (string or text) to use for storing
translations.

Here is an example defining three attributes on an ActiveRecord model:

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title, :author, backend: :key_value, type: :string, cache: false
  translates :content,        backend: :key_value, type: :text, fallbacks: true
end
```

`title`, `author` and `content` will use the `KeyValue` backend, which stores
translations on two shared translation tables (one for string-valued
translations and one for text-valued translations). The cache (enabled by
default) is disabled for `title` and `author` (but not `content`).
[Fallbacks](#fallbacks) are enabled for `content` (but not `title` or
`author`).

Finally, `title` and `author` store their translations as string columns
(`type: :string`) whereas `content` stores its values as text columns (`type:
:text`). The `type` key is a backend-specific option used by the `KeyValue`
backend.

Note that Mobility will detect the model class and use this to determine which
ORM-specific backend to use. In the example above, it will use
{Mobility::Backend::ActiveRecord::KeyValue}; if the class were a
`Sequel::Model`, it would have used {Mobility::Backend::Sequel::KeyValue}. In
general options to configure the backend are ORM-independent.

### Setting the Locale

Similar to [Globalize](https://github.com/globalize/globalize), Mobility has
its own `locale` which defaults to the value of `I18n.locale` but can also be
set independently with a setter:

```ruby
I18n.locale = :en
Mobility.locale              #=> :en
Mobility.locale = :fr
Mobility.locale              #=> :fr
I18n.locale                  #=> :en
```

To set the Mobility locale in a block, use {Mobility.with_locale}:

```ruby
Mobility.locale = :en
Mobility.with_locale(:ja) do
  Mobility.locale            #=> :ja
end
Mobility.locale              #=> :en
```

### Getting and Setting Translations

Mobility defines getter, setter, and presence methods for translated attributes
on the model class. Regardless of which backend you use to store translations,
the basic interface for accessing them is the same.

Assuming we have a model `Post` as above, we can first set the locale, then
create a post with a translated attribute:

```ruby
Mobility.locale = :en
post = Post.create(title: "Mobility")
post.title
#=> "Mobility"
post.title?
#=> true
```

Attributes can similarly be written just like a normal attribute:

```ruby
post.title = "Mobility (noun): quality of being changeable, adaptable or versatile"
post.title
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
```

If you change locale, you will read/write the attribute in that locale:

```ruby
Mobility.locale = :ja
post.title
#=> nil
post.title?
#=> false
post.title = "Mobility(名詞):動きやすさ、可動性"
post.title
#=> "Mobility(名詞):動きやすさ、可動性"
post.title?
#=> true
```

Internally, Mobility maps the `title` accessor method to a backend, which then
handles reading and writing of data. You can access the backend instance for a
given attribute with `<attribute>_backend`, in this case `post.title_backend`,
and read and write locale values directly to/from the backend (although this
should not generally be necessary):

```ruby
post.title_backend.read(:ja)
#=> "Mobility(名詞):動きやすさ、可動性"
post.title_backend.read(:en)
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
```

You can also access different locales by passing the locale into the getter
method in the options hash:

```ruby
post.title(locale: :ja)
#=> "Mobility(名詞):動きやすさ、可動性"
post.title(locale: :en)
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
```

The translated value can be written using the backend's `write` method:

```ruby
post.title_backend.write(:en, "new title")
post.save
post.title
#=> "new title"
post.title_backend.write(:en, "Mobility (noun): quality of being changeable, adaptable or versatile")
post.save
post.title
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
```

Backends vary in how they implement reading and writing of translated
attributes. The default {Mobility::Backend::KeyValue} backend stores these translations on two
shared tables, `mobility_string_translations` and `mobility_text_translations`,
depending on the `type` of the attribute (corresponding to the type of column
used).

For more details on backend-specific options, see the documentation for each
backend ([below](#backend)).

### <a name="backend"></a>Choosing a Backend

Mobility supports six different (database) backends:

- **`:column`** ({Mobility::Backend::Column})<br>
  Store translations as columns on a table with locale as a postfix, of the
  form `title_en`, `title_fr`, etc. for an attribute `title`.
- **`:table`** ({Mobility::Backend::Table})<br>
  Store translations on a model-specific table, e.g. for a model `Post` with
  table `posts`, store translations on a table `post_translations`, and join
  the translation table when fetching translated values.
- **`:key_value`** ({Mobility::Backend::KeyValue})<br>
  Store translations on a shared table of locale/attribute translation pairs,
  associated through a polymorphic relation with multiple models.
- **`:serialized`** ({Mobility::Backend::Serialized})<br>
  Store translations as serialized YAML or JSON on a text column.
- **`:hstore`** ({Mobility::Backend::Hstore})<br>
  Store translations as values of a hash stored as a PostgreSQL hstore column.
- **`:jsonb`** ({Mobility::Backend::Jsonb})<br>
  Store translations as values of a hash stored as a PostgreSQL jsonb column.

Each backend has strengths and weaknesses. If you're unsure of which backend to
use, a rule of thumb would be:

- If you're using PostgreSQL as your database, use `:jsonb`.
- If you have a fixed, small set of locales that are not likely to increase,
  and have a small number of models to translate, consider `:column`.
- If you have a small set of models to be translated but translation to
  potentially many different languages, consider `:table`.
- For all other cases (many locales, many translated models), or if you're just
  not sure, the recommended solution is `:key_value` for maximum flexibility
  and minimum database migrations.


### <a name="locale-accessors"></a>Locale Accessors

It can sometimes be more convenient to access translations through dedicated
locale-specific methods (for example to update multiple locales at once in a
form). For this purpose, Mobility has a `locale_accessors` option that can be
used to define such methods on a given class:

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title, locale_accessors: [:en, :ja]
end
```

(Note: The backend defaults to `key_value`, and `type` defaults to `text`, but
options described here are independent of backend so we will omit both for what
follows.)

Since we have enabled locale accessors for English and Japanese, we can access
translations for these locales with:

```ruby
post.title_en
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
post.title_ja
#=> "Mobility(名詞):動きやすさ、可動性"
post.title_en = "foo"
post.title
#=> "foo"
```

Alternatively, just using `locale_accessors: true` will enable all locales in
`I18n.available_locales`.

For more details, see: {Mobility::Attributes} (specifically, the private method
`define_locale_accessors`).

### <a name="cache"></a>Cache

The Mobility cache caches localized values that have been fetched once so they
can be quickly retrieved again, and also speeds up writes for some backends.
The cache is enabled by default and should generally only be disabled when
debugging; this can be done by passing `cache: false` to any backend.

In general, you should not need to actually see the cache, but for debugging
purposes you can access it by calling the private `cache` method on the
backend:

```ruby
post.title_backend.send :cache
#=> #<Mobility::Backend::KeyValue::TranslationsCache:0x0056139b391b38 @cache={}>
```

For more details, see: {Mobility::Backend::Cache}.

### <a name="fallbacks"></a>Fallbacks

Mobility offers basic support for translation fallbacks (similar to gems such
as [Globalize](https://github.com/globalize/globalize) and
[Traco](https://github.com/barsoom/traco)). To enable fallbacks, pass a hash
with fallbacks for each locale as an option to the backend:

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title, locale_accessors: [:en, :ja, :fr], fallbacks: { en: :ja, fr: :ja }
end
```

By setting fallbacks for English and French to Japanese, values will fall
through to the Japanese value if none is present for either of these locales:

```ruby
Mobility.locale = :en
post = Post.first
post.title = nil
post.save
post.title_en
#=> "Mobility(名詞):動きやすさ、可動性"
post.title_ja
#=> "Mobility(名詞):動きやすさ、可動性"
post.title_fr
#=> "Mobility(名詞):動きやすさ、可動性"
```

You can optionally disable fallbacks to get the real value for a given locale
(for example, to check if a value in a particular locale is set or not) by
passing `fallbacks: false` to the getter method:

```ruby
post.title(fallbacks: false)
#=> nil
post.title_fr(fallbacks: false)
#=> nil
```

(Mobility assigns the fallbacks hash to an instance of
`I18n::Locale::Fallbacks.new`.)

For more details, see: {Mobility::Backend::Fallbacks}.

### <a name="dirty"></a>Dirty Tracking

Dirty tracking (tracking of changed attributes) can be enabled for models which support it. Currently this includes models including `ActiveModel::Dirty` or Sequel models with the `dirty` plugin enabled.

Enabling dirty tracking is as simple as sending the `dirty: true` option to any
backend. The way dirty tracking works is somewhat dependent on the model class
(ActiveModel or Sequel); we will describe the ActiveModel implementation here.

First, enable dirty tracking (note that this is a persisted AR model, although
dirty tracking is not specific to AR and works for non-persisted models as well):

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title, locale_accessors: [:en, :ja], dirty: true
end
```

Now set the attribute in both locales:

```ruby
post.title
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
post.title = "a new title"
post.title_ja
#=> "Mobility(名詞):動きやすさ、可動性"
post.title = "新しいタイトル"
```

Now you can use dirty methods as you would any other (untranslated) attribute:

```ruby
post.title_was
#=> "Mobility (noun): quality of being changeable, adaptable or versatile"
Mobility.locale = :ja
post.title_was
#=> "Mobility(名詞):動きやすさ、可動性"
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
      "Mobility (noun): quality of being changeable, adaptable or versatile",
      "a new title"
    ],
  "title_ja" =>
    [
      "Mobility(名詞):動きやすさ、可動性",
      "新しいタイトル"
    ]
}
```

You will notice that Mobility uses locale accessors to indicate which locale
has changed; dirty tracking is implemented this way to ensure that it is clear
what has changed in which locale, avoiding any possible ambiguity.

For more details, see: {Mobility::Backend::Dirty}.

### <a name="querying"></a>Querying

Database-backed Mobility backends also optionally support querying through
`where` and other query methods (`not` and `find_by` for ActiveRecord models,
`except` for Sequel models, etc). To query on these attributes, use the `i18n`
class method, which will return a model relation extended with
Mobility-specific query method overrides.

So assuming a model:

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title, backend: :key_value, type: :string
  translates :content, backend: :key_value, type: :text
end
```

we can query for posts with title "foo" and content "bar" just as we would
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
  WHERE "content_mobility_text_translations"."value" = 'bar' AND
  "title_mobility_string_translations"."value" = 'foo'
```

As can be seen in the query above, behind the scenes Mobility joins two tables,
one with string translations and one with text translations, and aliases the
joins for each attribute so as to match the particular values passed in to the
query. Details of how this is done can be found in
{Mobility::Backend::ActiveRecord::QueryMethods}.

Note that this feature is available for all backends *except* the `serialized`
backend, since serialized database values are not query-able (an
`ArgumentError` error will be raised if you try to query on attributes of this
backend).

For more details, see subclasses of
{Mobility::Backend::ActiveRecord::QueryMethods} or
{Mobility::Backend::Sequel::QueryMethods}.

## Philosophy

As its name implies, Mobility was created with a very specific design goal: to
separate the problem of translating model attributes from the constraints of
any particular translation solution, so that application designers are free to
mix, match and customize strategies to suit their needs.

To this end, Mobility backends strictly enforce the rule that *no backend
should modify a parent class in any way which would interfere with other
backends operating on the same class*. This is done using a heavy dose of
metaprogramming, details of which can be found in the [API
documentation](http://www.rubydoc.info/gems/mobility/0.1.1) and in the actual code.

In practice, this means that you can use different backends for different
attributes *on the same class* without any conflict, e.g. (assuming we
are using Postgres as our database):

```ruby
class Post < ActiveRecord::Base
  include Mobility
  translates :title,       backend: :key_value, type: :string
  translates :content,     backend: :column, cache: false
  translates :author_name, backend: :jsonb
end
```

Attributes can be set and fetched and Mobility will transparently handle
reading and writing through the respective backend: a shared
`mobility_string_translations` table for `title`, the `content_en` and
`content_ja` columns on the `posts` table for `content`, and JSON keys and
values on the jsonb `author_name` column for `author_name`.

Similarly, we can query for a particular post using the `i18n` scope without worrying about how attributes are actually stored. So this query:

```ruby
Post.i18n.where(title: "foo",
                content: "bar",
                author_name: "baz")
```

will result in the following SQL:

```sql
SELECT "posts".* FROM "posts"
  INNER JOIN "mobility_string_translations" "title_mobility_string_translations"
  ON "title_mobility_string_translations"."key" = 'title'
  AND "title_mobility_string_translations"."locale" = 'en'
  AND "title_mobility_string_translations"."translatable_type" = 'Post'
  AND "title_mobility_string_translations"."translatable_id" = "posts"."id"
  WHERE (posts.author_name @> ('{"en":"baz"}')::jsonb)
  AND "posts"."content_en" = 'bar'
  AND "title_mobility_string_translations"."value" = 'foo'
```

The query combines conditions specific to each backend, together fetching the
record which satisfies all of them.

Beyond the goal of making it easy to combine backends in a single class (which
admittedly is a rather specialized use-case), the flexibility Mobility enforces
makes it possible to build more complex translation-based applications without
worrying about the details of the translation storage strategy used. It also
saves effort in integrating translation storage with various other gems, since
only one integration is required rather than one for each translation gem.

## Development

### Custom Backends

Although Mobility is primarily oriented toward storing ActiveRecord model
translations, it can potentially be used to handle storing translations in
other formats, for example in the cloud through an API, or in files. In
particular, the features mentioned above (locale accessors, caching, fallbacks,
dirty tracking to some degree) are not specific to database storage.

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

For details on how to define a backend class, see the {Mobility::Backend}
module and other classes defined in the [API
documentation](http://www.rubydoc.info/gems/mobility/0.1.1).

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

## More Information

- [Github repository](https://www.github.com/shioyama/mobility)
- [API documentation](http://www.rubydoc.info/gems/mobility/0.1.1)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
