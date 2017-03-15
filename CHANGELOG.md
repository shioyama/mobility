# Mobility Changelog

## 0.1

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
