# Mobility Changelog

## 0.8

### 0.8.0 (September 11, 2018)
* Support order clause on translated queries (ActiveRecord)
  ([#261](https://github.com/shioyama/mobility/pull/261))
* Restructure Sequel querying into plugin
  ([#255](https://github.com/shioyama/mobility/pull/255),
  [#267](https://github.com/shioyama/mobility/pull/267),
  [#268](https://github.com/shioyama/mobility/pull/267))
* Default locale to Mobility.locale in apply_scope
  ([#263](https://github.com/shioyama/mobility/pull/263))
* Require Ruby version 2.3.7 or greater
  ([#242](https://github.com/shioyama/mobility/pull/242))

### 0.7.6 (July 6, 2018)
* Sequel pg_hash require hash_initializer
  ([#260](https://github.com/shioyama/mobility/pull/260)). Thanks
  [@Recca](https://github.com/Recca)!

### 0.7.5 (June 8, 2018)
* Only return unique names from mobility_attributes
  ([#256](https://github.com/shioyama/mobility/pull/256))

### 0.7.4 (June 8, 2018)
* Handle locales with multiple dashes in locale accessors, or raise
  ArgumentError for invalid format
  ([#253](https://github.com/shioyama/mobility/pull/253))

### 0.7.3 (June 7, 2018)
* Fix uniqueness on Mobility model with no translated attributes
  ([#252](https://github.com/shioyama/mobility/pull/252))

### 0.7.2 (June 3, 2018)
* Normalize locale in table aliases
  ([#246](https://github.com/shioyama/mobility/pull/246))

### 0.7.1 (May 30, 2018)
* Revert unscoping in uniqueness validator
  ([#244](https://github.com/shioyama/mobility/pull/244))

### 0.7.0 (May 30, 2018)

* Restructure querying into plugin (ActiveRecord only)
  ([#216](https://github.com/shioyama/mobility/pull/216),
  [#225](https://github.com/shioyama/mobility/pull/225),
  [#222](https://github.com/shioyama/mobility/pull/222))
* Support querying on multiple locales at once
  ([#232](https://github.com/shioyama/mobility/pull/232))
* Allow passing locale to query methods
  ([#233](https://github.com/shioyama/mobility/pull/233))
* Support matches and lower predicate methods
  ([#235](https://github.com/shioyama/mobility/pull/235))
* Implement case-insensitive uniqueness validation
  ([#236](https://github.com/shioyama/mobility/pull/236),
  [#237](https://github.com/shioyama/mobility/pull/237))
* Support equality predicates between jsonb nodes
  ([#240](https://github.com/shioyama/mobility/pull/240))
* Prefer -> operator when comparing jsonb columns
  ([#241](https://github.com/shioyama/mobility/pull/241))
* Define options on subclassed backend class
  ([#218](https://github.com/shioyama/mobility/pull/218))
* Add column_affix when configuring options
  ([#217](https://github.com/shioyama/mobility/pull/217))
* Use module_eval to define locale_accessors
  ([#219](https://github.com/shioyama/mobility/pull/219))
* Improve performance of getters/setters
  ([#220](https://github.com/shioyama/mobility/pull/220))
* Do not include Default plugin by default
  ([#223](https://github.com/shioyama/mobility/pull/223))
* Add specific attribute types to basic usage example
  ([#228](https://github.com/shioyama/mobility/pull/228)). Thanks
  [thatguysimon](https://github.com/thatguysimon)!
* Remove Mobility::Interface
  ([#229](https://github.com/shioyama/mobility/pull/229))
* Freeze attributes array
  ([#230](https://github.com/shioyama/mobility/pull/230))

## 0.6

### 0.6.0 (April 26, 2018)

* Add column_prefix/column_suffix options to hash backends
  ([#200](https://github.com/shioyama/mobility/pull/199) and
  [#201](https://github.com/shioyama/mobility/pull/201))
* Require specifying type for KeyValue backends
  ([#200](https://github.com/shioyama/mobility/pull/200))
* Remove table backend index on foreign key alone
  ([#198](https://github.com/shioyama/mobility/pull/198))
* Test/cleanup index name truncation in backend generators
  ([#197](https://github.com/shioyama/mobility/pull/197))
* Improve translations generators
  ([#196](https://github.com/shioyama/mobility/pull/196))
* Enforce null: false constraint on columns consistently
  ([#205](https://github.com/shioyama/mobility/pull/205))
* Add extension to find translations in a locale for Table backend
  ([#202](https://github.com/shioyama/mobility/pull/202))
* Ignore non-arel nodes in joins_values
  ([#206](https://github.com/shioyama/mobility/pull/206))
* Collapse duplicates in array-valued query hash
  ([#207](https://github.com/shioyama/mobility/pull/207))
* Remove unneeded anonymous module in backend resetters
  ([#213](https://github.com/shioyama/mobility/pull/213))
* Make constants private
  ([#214](https://github.com/shioyama/mobility/pull/214))
* Use IN when querying on array values with PG backends
  ([#209](https://github.com/shioyama/mobility/pull/209))
* Remove some deprecated methods
  ([#215](https://github.com/shioyama/mobility/pull/215))
* Explicitly implement matches/has_locale methods everywhere
  ([#194](https://github.com/shioyama/mobility/pull/194))
* Refactor Mobility::Backends::AR::QueryMethods using MobilityWhereChain module
  ([#193](https://github.com/shioyama/mobility/pull/193))
* Add missing documentation
  ([#192](https://github.com/shioyama/mobility/pull/192))

## 0.5

### 0.5.1 (March 21, 2018)
* Fix issues with Dirty plugin in ActiveRecord 5.2.0.rc2
  ([#166](https://github.com/shioyama/mobility/pull/166))

### 0.5.0 (March 16, 2018)
* Support PostgreSQL json column format as Json backend and dynamically in
  Container backend ([#182](https://github.com/shioyama/mobility/pull/182) and
  [#184](https://github.com/shioyama/mobility/pull/184), respectively)
* Fall through to `I18n.fallbacks` when defined
  ([#180](https://github.com/shioyama/mobility/pull/180))
* Improve comments in Rails initializer
  ([#186](https://github.com/shioyama/mobility/pull/186))
* Use pragma comments to freeze strings everywhere
  ([#177](https://github.com/shioyama/mobility/pull/177))

## 0.4

### 0.4.3 (February 18, 2018)
* Add missing require in container backend
  ([#174](https://github.com/shioyama/mobility/pull/174))
* Update dependencies to support i18n v1.0
* Use `locale: true` instead of `fallback: false` in dirty plugin
  ([a52998](https://github.com/shioyama/mobility/commit/a52998479893e33a6df5bfd395f50f76884cf64e))

### 0.4.2 (January 29, 2018)
* Refactor find_by for translated attributes
  ([#160](https://github.com/shioyama/mobility/pull/160))

### 0.4.1 (January 29, 2018)
* Use element operator instead of contains for jsonb querying
  ([#159](https://github.com/shioyama/mobility/pull/159))

### 0.4.0 (January 24, 2018)
* Add new jsonb Container backend
  ([#157](https://github.com/shioyama/mobility/pull/157))
* Define attributes accessors with eval
  ([#152](https://github.com/shioyama/mobility/pull/152))
* Rename `default_fallbacks` to `new_fallbacks` / `fallbacks_generator=`
  ([#148](https://github.com/shioyama/mobility/pull/148))
* Warn user if `case_sensitive` option is passed to ActiveRecord uniqueness
  validator ([#146](https://github.com/shioyama/mobility/pull/146))
* Handle array of values to translated attribute query
  ([#128](https://github.com/shioyama/mobility/pull/128))
* Use module builder instance to define shared methods in closure
  ([#130](https://github.com/shioyama/mobility/pull/130))
* Query on translated json value with Sequel ORM
  ([#155](https://github.com/shioyama/mobility/pull/155))
* Refactor pg query methods ([#129](https://github.com/shioyama/mobility/pull/129))
* Reduce object allocations
  ([#156](https://github.com/shioyama/mobility/pull/156))

## 0.3

### 0.3.6 (December 25, 2017)
* Make `_read_attribute` public in AR Dirty plugin
  ([#150](https://github.com/shioyama/mobility/pull/150))

### 0.3.5 (December 24, 2017)
* Make Default plugin handle Procs more gracefully
  ([#137](https://github.com/shioyama/mobility/pull/137))
* Show deprecation warning if keyword options passed to Default plugin
  ([#147](https://github.com/shioyama/mobility/pull/147))

### 0.3.4 (December 6, 2017)
* Move `translated_attribute_names` to `Mobility::ActiveRecord`
  ([#132](https://github.com/shioyama/mobility/pull/129))
* Refactor AR pg query methods ([#129](https://github.com/shioyama/mobility/pull/129))

### 0.3.3 (December 5, 2017)
* Fix duping for AR KeyValue backend ([#126](https://github.com/shioyama/mobility/pull/126))
* Pass locale and options to Proc in default plugin ([#122](https://github.com/shioyama/mobility/pull/122))

### 0.3.2 (December 1, 2017)
* Fix issue with querying on translated attributes with Sequel Table backend ([#121](https://github.com/shioyama/mobility/pull/121))

### 0.3.1 (December 1, 2017)
* Disable AR::Dirty method overrides for AR >= 5.2 (and < 5.1 for `has_attribute`) ([#120](https://github.com/shioyama/mobility/pull/120))

### 0.3.0 (November 30, 2017)
* `dup` support for table backend ([#84](https://github.com/shioyama/mobility/pull/84)). Thanks [@pwim](https://github.com/pwim)!
* Disable fallbacks when using locale/fallthrough accessors
  ([#86](https://github.com/shioyama/mobility/pull/86), [#87](https://github.com/shioyama/mobility/pull/87),
  [#88](https://github.com/shioyama/mobility/pull/88), [#89](https://github.com/shioyama/mobility/pull/89))
* Convert AttributeMethods to plugin
  ([#102](https://github.com/shioyama/mobility/pull/102))
* Ensure `cache_key` is invalidated when updating translations
  ([#104](https://github.com/shioyama/mobility/pull/102)) Thanks
  [@pwim](https://github.com/pwim)!
* Update dependency versions ([#107](https://github.com/shioyama/mobility/pull/107))
* Fix AM/AR Dirty plugin issues with Rails 5.2 ([#116](https://github.com/shioyama/mobility/pull/116))
* Support new AR::Dirty methods ([#111](https://github.com/shioyama/mobility/pull/111))
* Use `public_send` in LocaleAccessors plugin ([#117](https://github.com/shioyama/mobility/pull/117))
* Deprecate setting value of `default_options` directly ([#113](https://github.com/shioyama/mobility/pull/113))

## 0.2

### 0.2.3 (September 14, 2017)
* Fix inheritance error when inheriting
  ([#83](https://github.com/shioyama/mobility/pull/83)). Thanks
  [pwim](https://github.com/pwim)!

### 0.2.2 (August 23, 2017)
* Set default values in Sequel Jsonb/Hstore backends ([#80](https://github.com/shioyama/mobility/pull/80))

### 0.2.1 (August 20, 2017)

* Fix missing requires in `Mobility::Backends::Sequel::PgHash` ([22df29](https://github.com/shioyama/mobility/commit/22df2946bcccadd7dff0880539ac828c42111adc))
* Only require Rails generators if both Rails and ActiveRecord are loaded ([03a9ff](https://github.com/shioyama/mobility/commit/03a9ffe7009332f81ea7197dbce00c357e8d4b0c))

### 0.2.0 (August 13, 2017)

See overview of the changes in [this blog
post](http://dejimata.com/2017/8/13/mobility-0-2-now-with-plugins).

* Mobility.default_options ([#50](https://github.com/shioyama/mobility/pull/50))
* Re-organized options under Plugins namespace ([#62](https://github.com/shioyama/mobility/pull/64))
* Backends are now Enumerable ([#71](https://github.com/shioyama/mobility/pull/71))
* Replace `autoload` by `require` ([#65](https://github.com/shioyama/mobility/pull/65))
* Remove mobility/core_ext and replace with `Mobility::Util` ([#60](https://github.com/shioyama/mobility/pull/60))
* New "default" plugin which sets a default value or proc for an attribute: ([#49](https://github.com/shioyama/mobility/pull/49))
* Add `super` option ([#62](https://github.com/shioyama/mobility/pull/62))
* Rename default associations for KeyValue and Table backends ([#59](https://github.com/shioyama/mobility/pull/59) and [#66](https://github.com/shioyama/mobility/pull/66))
* Refactor cache code ([#57](https://github.com/shioyama/mobility/pull/58))
* Gem is now signed ([#73](https://github.com/shioyama/mobility/pull/73))
* Minimum Ruby version: 2.2.7

## 0.1

### 0.1.20 (July 23, 2017)
* Fix location of Rails generators to work with plugins
  ([#56](https://github.com/shioyama/mobility/pull/56))

### 0.1.19 (July 16, 2017)
* Partial support for AR 4.2 ([#46](https://github.com/shioyama/mobility/pull/46))
* Fix issues with Sequel >= 4.46.0 ([#47](https://github.com/shioyama/mobility/pull/47))
* Include anonymous modules instead of defining methods directly on class
  ([049a5f](https://github.com/shioyama/mobility/commit/049a5f90fd898d82984d2fe1af1646fda48ad142),
  [d8fe42](https://github.com/shioyama/mobility/commit/d8fe42f81211640125e6a50bf681d45dbaa71c40),
  [9cc3d0](https://github.com/shioyama/mobility/commit/9cc3d0e8c3f813c15213848f305e363c4eec6b8e))

### 0.1.18 (June 21, 2017)
* Fix deprecation warnings when using ActiveRecord 5.1
  ([#44](https://github.com/shioyama/mobility/pull/44))

### 0.1.17 (June 16, 2017)
* Fix STI issues ([#43](https://github.com/shioyama/mobility/pull/43))

### 0.1.16 (May 29, 2017)
* Fix deprecation warnings using class_name ([#32](https://github.com/shioyama/mobility/pull/32))
* Avoid using respond_to? on relation, to fix ImmutableRelation exception
  ([d3e974](https://github.com/shioyama/mobility/commit/d3e974855f7e772b5df43f665a2251a1982cfff0)).

### 0.1.15 (May 21, 2017)
* Add support for uniqueness validation ([#28](https://github.com/shioyama/mobility/pull/28))
* Inherit translated attributes in subclasses ([#30](https://github.com/shioyama/mobility/pull/30))

### 0.1.14 (April 27, 2017)
* Reset memoized backends when duplicating ([#26](https://github.com/shioyama/mobility/issues/25))

### 0.1.13 (April 19, 2017)
* Allow passing `cache: false` to disable cache in getter
  ([b4858a](https://github.com/shioyama/mobility/commit/b4858acfb0cf5dae0761672269c248d0e3762bab))
  and setter
  ([6085d7](https://github.com/shioyama/mobility/commit/6085d791a98de7870bdd78fe6b792cbb3f96c1f4))
* Rename `configure!` method to `configure`
  ([4e35c54](https://github.com/shioyama/mobility/commit/4e35c54cd62033d1ce7b631a1f62efaf4ffa2565))
* Make query scope method configurable ([#22](https://github.com/shioyama/mobility/pull/22))
* Do not memoize scopes/datasets ([#24](https://github.com/shioyama/mobility/pull/24))

### 0.1.12
* Extract presence filter into `Mobility::Backend::Presence` class
  ([7d654](https://github.com/shioyama/mobility/commit/7d65479c832ca154a45a548b64d27016486d34df),
  [e42ee6](https://github.com/shioyama/mobility/commit/e42ee6123197594f3a8d694bff68c2ef4044562e))
* Get suffix methods from ActiveModel (for compatibility with Rails 4.2)
  ([9685d1](https://github.com/shioyama/mobility/commit/9685d182f285bddd2f5739a655f7c9e18998a5a1))
* Destroy all translations after model is destroyed (KeyValue backend)
  ([#15](https://github.com/shioyama/mobility/pull/15))
* Refactor to remove `mobility_get`, `mobility_set`. `mobility_present?` models
  from model class ([#16](https://github.com/shioyama/mobility/pull/16))

### 0.1.11
* Add backend-specific translations generator (`rails generate
  mobility:translations`)
  ([9dbe4d](https://github.com/shioyama/mobility/commit/9dbe4d2221f3c97ec265c297ad2be201a5180151),
  [583a51](https://github.com/shioyama/mobility/commit/583a51c9945615460079a1f81ffbd7a69d91a581),
  [6b9605](https://github.com/shioyama/mobility/commit/6b9605ed6fa599578fd36065ac17e6b2b93a8378),
  [e2e807](https://github.com/shioyama/mobility/commit/e2e807494bd1f642c67a0dbd678cea49b16f11b0))
* Fix bug with combination of Column backend and fallthrough accessors
  ([212f07](https://github.com/shioyama/mobility/commit/212f078145f613ab85faf7dbf993c7da9a91bcdd))
* Raise `InvalidLocale` when getting a locale that is not available
  ([d4f0ee](https://github.com/shioyama/mobility/commit/d4f0ee20d5507ba147f31aa03081f685e31ab46a))
* Pass options to backend write from setter
  ([5d224f](https://github.com/shioyama/mobility/commit/5d224fa7bb877d9dc1f6c3983b096b22aeea5bc7))
* Correctly include `FallthroughAccessors` module in module, not backend
  ([d9471d](https://github.com/shioyama/mobility/commit/d9471db7ab71766a98e4e411b476d2197fbf7f51))
* Handle presence methods in `FallthroughAccessors`
  ([66f630](https://github.com/shioyama/mobility/commit/66f630548c01b8d380c6aeeab4c32b085133c754))

### 0.1.10
* Fix fallback options ([#12](https://github.com/shioyama/mobility/pull/12) and
  [09a163](https://github.com/shioyama/mobility/commit/09a1636bc743633fd13dc6c59ebf1e2366a0e2c4))
* Include fallbacks module by default
  ([#13](https://github.com/shioyama/mobility/pull/13/files))


### 0.1.9

(yanked)

### 0.1.8

(yanked)

### 0.1.7
* Allow passing fallback locale or locales to getter method
  ([#9](https://github.com/shioyama/mobility/pull/9))
* Add missing indices on key-value string/text translation tables
  ([1e00e0](https://github.com/shioyama/mobility/commit/1e00e0d957478f2408fbac1ee853f829489263e2),
  [574172](https://github.com/shioyama/mobility/commit/574172dc88823a35c60ff963ff9c40b7c05771d7))

### 0.1.6
* Return accessor locales instead of Proc from default_accessor_locales
  ([825f75](https://github.com/shioyama/mobility/commit/825f75de6107287a5de70db439d8aec5e4a47977))
* Fix support for locales in dirty modules
  ([0b40d6](https://github.com/shioyama/mobility/commit/0b40d66ea0c816d4fb57deceff9344f5128a593f))
* Add FallthroughAccessors for use in dirty modules
  ([#4](https://github.com/shioyama/mobility/pull/4))
* Only raise InvalidLocale exception if I18n.enforce_available_locales is true
  ([979c36](https://github.com/shioyama/mobility/commit/979c365794d3df90a2d23ad50519ff354686a493))

### 0.1.5
* Add `accessor_method` to default initializer ([d4a9da](https://github.com/shioyama/mobility/commit/d4a9da98cae71de2fb9ee3d29c64decef5a16010))
* Include AR version in generated migrations ([ac3dfb](https://github.com/shioyama/mobility/commit/ac3dfbbc053089b01dcc73d0b617fefaeaaa85cb))
* Add `untranslated_attributes` method ([50e97f](https://github.com/shioyama/mobility/commit/50e97f12ea219321ef9f61792e909299f570ba23))
* Do not require `active_support/core_ext/nil` ([39e245](https://github.com/shioyama/mobility/commit/39e24596482f03302542e524ca6f17275a778644))
* Handle false values correctly when getting and setting ([bdf6f1](https://github.com/shioyama/mobility/commit/bdf6f199aaa8318a73c5aa6332aee8d7aad254f6))
* Use proc to define accessor locales from `I18n.available_locales` ([3cd786](https://github.com/shioyama/mobility/commit/3cd786814d8044ae5d64f939c3a7b5c49b322bc6))
* Do not mark attribute as changed if value is the same (fixed in [#2](https://github.com/shioyama/mobility/pull/2))
* Pass on any args to original reload method when overriding (fixed in [#3](https://github.com/shioyama/mobility/pull/3))

### 0.1.4
* Fix configuration reload issue ([#1](https://github.com/shioyama/mobility/issues/1), fixed in [478b66](https://github.com/shioyama/mobility/commit/478b669dae90edf9feb7c011ae93e8157dc4e2b4))
* Code refactoring/cleanup ([e4dcc7](https://github.com/shioyama/mobility/commit/e4dcc791c246e377352b9ac154d2b1c4aec8e98e), [64f434](https://github.com/shioyama/mobility/commit/64f434ea7a46c9353c3638c58a3258f0fcb81821), [8df2bb](https://github.com/shioyama/mobility/commit/8df2bbdead883725d2c87020f836b644b4d28e5c), [326a09](https://github.com/shioyama/mobility/commit/326a0977c98348dad85a927c20dd69fe5acb2a9e))
* Allow using Sequel `plugin` to include Mobility in model ([b0db7c](https://github.com/shioyama/mobility/commit/b0db7cc28a47e13c6888ef263260e8dff281543d))

### 0.1.3

* Add homepage to gemspec
* Pass backend class as context to `translates`
  ([adf93e](https://github.com/shioyama/mobility/commit/adf93e3c6bb314b73fbd43b221819310a1407c4d))

### 0.1.2

* Fix issues with querying in ActiveRecord jsonb and hstore backends
  ([527908](https://github.com/shioyama/mobility/commit/527908d9317daee6bf91e3e1a188fb64365f7bab)
  and
  [5e6add](https://github.com/shioyama/mobility/commit/5e6addd6f01cf255f5e71666324502ace96d3eac))
