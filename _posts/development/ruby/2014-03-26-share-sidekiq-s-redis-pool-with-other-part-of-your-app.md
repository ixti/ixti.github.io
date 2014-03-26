---
layout:    post
title:     Share Sidekiq's redis pool with other part of your app
category:  development/ruby
tags:      [ruby, rails, redis, sidekiq, semaphore]
---

If you are running [Sidekiq][], then, most likely you would like to share it's
redis connection with other bits of your application. For example, you want to
implement a throttler for some Rails action, or you want to use some gem, that
needs redis, e.g. [redis-semaphore][]. Well, it's easier than it might sound...

[Sidekiq]: https://github.com/mperham/sidekiq/
[redis-semaphore]: https://github.com/dv/redis-semaphore/

This snippet was extrcated from one of Rails applications I have honor to work
on, but it can be used in any other application. There's only one bit that
relies on Rails: `MyApplication::Redis#url` - it uses `Rails.root`.

So you should put this snippet somewhere in your app. On Rails, a good
choice will be `config/initializers/00_redis.rb`.


```ruby
module MyApplication
  module Redis
    class Pool < ::ConnectionPool
      attr_accessor :namespace

      def initialize(options = {})
        super(options.delete :pool) { Redis.new options }
      end

      def with_namespace(ns)
        clone.tap { |o| o.namespace = ns }
      end

      def checkout(*args, &block)
        conn = super(*args, &block)

        if conn && namespace
          return ::Redis::Namespace.new namespace, :redis => conn
        end

        conn
      end

      def wrap
        Wraper.new self
      end

      class Wrapper < ::ConnectionPool::Wrapper
        def initialize(pool)
          @pool = pool
        end
      end
    end

    def pool
      @pool ||= Pool.new config
    end

    private

    def config
      {
        :url      => url,
        :driver   => :hiredis,
        :timeout  => 10.0,
        :pool     => { :size => pool_size }
      }
    end

    def pool_size
      case
      when ::Sidekiq.server? then Sidekiq.options[:concurrency] + 2
      else                        5
      end
    end

    def url
      @url ||= YAML.load(Rails.root.join("config", "redis.yml").read)
        .fetch(Rails.env) { fail "No Redis URL given in config/redis.yml" }
    end
  end


  def self.redis(*args, &block)
    return Redis.pool.wrap unless block_given?
    Redis.pool(*args, &block)
  end
end
```

Now, it's time to configure Sidekiq. It's pretty trivial, instead of passing
redis options, we will pass it a `ConnectionPool` instance:

``` ruby
Sidekiq.configure_client do |config|
  config.redis = ::MyApplication::Redis.pool.with_namespace "sidekiq"
end

Sidekiq.configure_server do |config|
  config.redis = ::MyApplication::Redis.pool.with_namespace "sidekiq"
end
```

And finally, with our `Pool::Wrapper` we can use it in redis-semaphore:

``` ruby
semaphore = Redis::Semaphore.new("foobar", :redis => MyApplication.redis)
```
