# Vache

Vache is a Hash-like data container that can be used like a cache, or
anything else where the data should be persisted for a limited amount
of time.

It behaves almost identically to Hash with a few additional methods
for manipulating expiry times and compacting to remove expired entries.

> Note that full compatibility with Hash is not yet guaranteed and additional
> implementation work is required.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vache'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install vache
```

## Usage

```ruby
cache = Vache.new

cache[:example] = true

cache[:example]
# => true
cache.key?(:example)
# => true
cache.include?(:example)
# => true

# Five minutes later, or after the default expiration time has passed
cache[:example]
# => nil
cache.key?(:example)
# => false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/postageapp/vache/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the vache project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/postageapp/vache/blob/master/CODE_OF_CONDUCT.md).
