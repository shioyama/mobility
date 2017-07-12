# Contributing to Mobility

Mobility is built to be developer friendly, with [detailed documentation](http://www.rubydoc.info/gems/mobility), a [Wiki](https://github.com/shioyama/mobility/wiki), and a very flexible interface. Contributions are welcome and encouraged! Bug reports, feature requests, and refactoring are all a great help, but please follow the instructions below to ensure things go as smoothly as possible.

## Bugs

Notice a bug or something that seems not to be working correctly? Great, that's valuable information. First off, make sure you go through the [Github issues](https://github.com/shioyama/mobility/issues?utf8=%E2%9C%93&q=is%3Aissue) to see if what you're experiencing has already been reported.

If not, please post a new issue explaining how the issue happens, and steps to reproduce it. Also include what backend you are using, what ORM (ActiveRecord, Sequel, etc.), what Ruby version, and if relevant what platform, etc.

## Feature Requests

Have an idea for a new feature? Great! Please sketch out what you are thinking of and create an issue describing it in as much detail as possible. Note that Mobility aims to be as simple as possible, so complex features will probably not be added, but extensions and integrations with other gems may be created outside of the Mobility gem itself.

## Questions

If you are having issues understanding how to apply Mobility to your particular use case, or any other questions about the gem, please post a question to [Stack Overflow](http://stackoverflow.com) tagged with "mobility". If you don't get an answer, you can post an issue to the repository with a link to the question and someone will try to help you asap.

## Features

If you've actually built a new feature for Mobility, go ahead and make a pull request and we will consider it. In general you will need to have tests for whatever feature you are proposing.

To test that your feature does not break existing specs, run the specs with:

```ruby
bundle exec rspec
```

This will run specs which are not dependent on any ORM (pure Ruby specs only). To test against ActiveRecord, you will need to set the `ORM` environment variable, like this:

```ruby
ORM=active_record bundle exec rspec
```

This will run AR specs with an sqlite3 in-memory database. If you want to run specs against a specific database, you will need to specify which database to use with the `DB` env (either `mysql` or `postgres`), and first create and migrate the database:

```ruby
ORM=active_record DB=postgres bundle exec rspec
```

... will run the specs against Mobility running with AR 5.1 with postgres as the database.

For more info, see the [Testing Backends](https://github.com/shioyama/mobility#testing-backends) section of the README.

Once you've ensured that existing specs do not break, please try to write at least one spec covering the new feature. If you have questions about how to do this, first post the PR and we can help you in the PR comments section.

Note that when you submit the pull request, Travis CI will run the [test suite](https://travis-ci.org/mobility/mobility) against your branch and will highlight any failures. Unless there is a good reason for it, we do not generally accept pull requests that take Mobility from green to red.
