---
layout:    post
title:     Delegate in Ruby and Rails
---

I believe most of developers in Rails community use `delegate` method to define
delegators, because (according to documentation) it looks nicer and it's API
more human readable. I disagree and encourage you to look at `Forwardable`.


First of all I would like to talk about "beauty". Since Ruby `1.9.1`,
`Forwardable` provides a decorated `def_instance_delegator` with API similar
to Rails one:

``` ruby
class Boss
  extend Forwardable

  # delegate single method
  delegate :schedule => :secretary

  # or a bunch of them
  delegate [:calls_filter, :mails_filter] => :secretary
end
```

Compare that to:

``` ruby
class Boss
  # delegate single method
  delegate :schedule, :to => :secretary

  # or a bunch of them
  delegate [:calls_filter, :mails_filter], :to => :secretary
end
```

Looks pretty similar, huh? So, what you will miss if you will use Ruby's
`def_instance_delegator` (or it's helper `delegate`)? The list is pretty short:

- Silent return of `nil` when target is `nil` and delegator defined
  with `:allow_nil => true` option.
- Automatic prefixing of bunch of delegated methods

So, why I prefer `def_instance_delegator` (or `def_delegator` shortcut)
instead? One pretty thing about `Forwardable`'s delegators is that you
can define custom generated delegator method name:

``` ruby
module Workers
  class Base
    extend Forwardable

    # define `option(key)` delegatred to `@options.fetch(key)`
    def_delegator :@options, :fetch, :option

    # mimic Rails' `:prefix => true` option of delegate method
    def_delegator :client, :address, :client_address
  end
end
```

Now let's talk about difference in wraper that is generated. Let's start
with Rails:

``` ruby
class Invoice
  delegate :address, :to => :client, :prefix => true

  # the above equals of writing following:

  def client_address(*args, &block)
    _ = client
    if !_.nil? || nil.respond_to?(:address)
      _.address(*args, &block)
    else
      raise DelegationError, "Invoice#client_address delegated to client.address, but client is nil: #{self.inspect}"
    end
  end
end
```

Now, let's see what `Forwardable` variant will generate for us:

``` ruby
class Invoice
  def_delegator :client, :address, :client_address

  # the above equals of writing following:

  def client_address(*args, &block)
    begin
      client.__send__(:address, *args, &block)
    rescue Exception
      $@.delete_if { |s| %r"#{Regexp.quote(__FILE__)}"o =~ s } unless Forwardable::debug
      ::Kernel::raise
    end
  end
end
```

As you can see main difference is that `Forwardable` version:

- does not checks whenever target responds to delegated message or not,
  and simply sends that message with given args and block if any.
- removes it's own trace lines from backtrace

Notice, that due to `Forwardable` uses `__send__` on target, it ignores
defined message visibility, so you can delegate to protected and private
methods of a target. Keep that in mind.

`Forwardable` can be used to define methods on instances as well:

``` ruby
some_object.extend Forwardable
some_object.delegate "puts" => "STDOUT"
some_object.puts "Tada!"
```

But, if you want to define delegators on instance you should better use
another delegation mixin: `SingleForwardable` (defined in `forwardable`).
Difference between two is that `Forwardable` tries to define method via
`module_eval` and then fall-backs to `instance_eval`, where `SingleForwardable`
uses only `instance_eval`. That actually allows you to define delegators
on class, so instead of writing something like this:

``` ruby
class Implementation
  def self.service
    puts "serviced!"
  end
end

class Facade
  class << self
    extend Forwardable
    def_delegator :Implementation, :service
  end
end

Facade.service # => "serviced!"
```

You can use `SingleForwardable` instead right on class:

```
class Implementation
  def self.service
    puts "serviced!"
  end
end

class Facade
  extend SingleForwardable
  def_delegator :Implementation, :service
end

Facade.service # => "serviced!"
```

The two variants above generate absolutely the same result. Notice that if you
want to use both `Forwardable` and `SingleForwardable` at the same time you can
use full names of helpers: `def_instance_delegator` and `def_single_delegator`.
But, in my opinion first variant (with `class << self` and `Forwardable`) looks
way more readable after all ;))
