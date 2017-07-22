# Mobility Changelog

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
