---
layout:   post
category: development/ruby
tags:     rack server rails sinatra ruby
title:    Understanding Rack Builder
---

Most of the web-frameworks for Ruby today use [Rack][1] - awesome web-server
interface [introduced][2] in 2007. Although Rack is not something new that just
released, most of us still aware of it _(Hi, varnak!)_, even denying the fact
that there's simple [tutorials][3] giving idea of how to build your own simple
application. Unfortunately, I didn't found good explanation about one of the
most awesome part of the Rack - Builder. So this post is some kind of reading
sources of Builder loud in order to understand it.

At first attempt I was going to explain the use and internals of `map` method
only. But then I realized that I can't. At least without explaining other
Builder's internals first. So let's go!


### Basic Information

First of all, I would like to mention important things about middlewares:

* each middleware is an object that responds to `call()` method
* `call()` method accepts only one argument - _environment_
* `call()` returns an array of
   * integer response code
   * hash of headers
   * array of body strings

Second important thing is that your _rackup_ file is running as part of
Builder's instance code. So `self` in that scope refers to main Builder's
instance. Dummy test explains it even better than I do:

``` bash
$ cat > demo.ru
puts self

$ rackup demo.ru
#<Rack::Builder:0x9b8a728>
[2011-09-03 16:22:20] INFO  WEBrick 1.3.1
...
```


### Executing Middlewares' Stack

This is the most interesting part. Every time you call `use()` method of Builder
instance it adds a procedure that creates instance of given middleware with
giving application to it. So `@use` array consist of something like this:

``` ruby
proc { |app| Rack::Static.new app, {:urls => '/images', :root => 'public'} }
```

Also, Builder instance has an associated application which is given by `run()`
method:

``` ruby
def run(app)
  @run = app
end
```

Now, when request is being processed, `call()` method of Builder instance is
triggered. In it's turn it grabs `app` variable as result of generated map of
applications (will discuss later) or `@run` instance. After that it finds first
middleware in the `@use` stack and proxies `call()` to it.

Let's take a look on this method more preciously. Inside the `call()` method of
Builder instance it first defines variable (in the scope of method): `app` which
is either an application from the `mappings` or `@run`. Then it reverses `@use`
stack - so the last defined (with `use()` method) becomes the first element of
array - calls each `proc` and returns the latest result. Here's basic idea of
what's going on:

``` ruby
@use.reverse.inject(@run){ |app,factory| factory[app] }.call(env)
```

As you can see each iterator block returns result of executing of procedure with
passing `app` local variable. So to make sure we all understand the magic above
here what happens explained:

``` ruby
def call(env)
  app = @map ? generate_map(@run, @map) : @run
  fail "missing run or map statement" unless app

  # first we are getting reversed array of factories
  # then we are calling inject with initial memo = app
  # memo - is the first argument of inject block (`a` in our case)
  # after all latest memo is returned
  first = @use.reverse.inject(app) { |a,e|
    # `a` is a reference to app (when this block is called for the first element
    # of array) or a reference to the result of previous iteration
    # e is a `proc` object and calling e[a] is a shorthand to e.call(a)
    e.call(a)
  }

  # inject returns latest value of memo, which is either app itself when @use is
  # empty, or first middleware instance from the stack
  first.call(env)
end
```

So the main magic is - `inject` method. If our `@use` stack is empty it will
return object given as initial memo - `app` in our case, otherwise it will
return the latest result of the block. To understand how inject works, let's
see it on dummy example:

``` ruby
puts %w[b c d e].inject('a'){ |prev,curr| "#{prev} -> #{curr}" }
```

The above will output `a -> b -> c -> d -> e` string. So now you got more info
about magic's background ;)) Let's take a look at this magic again but with
synthetic example (refer to _stacking.rb_ at the bottom). First of all let's
define three classes _DummyA_, _DummyB_ and _DummyC_:

``` ruby
class DummyA
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyA'
    str.upcase
  end
end


class DummyB
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyB'
    str.downcase
  end
end


class DummyC
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyC'
    @app.call(str)
  end
end
```

Each of them can be used as application or as middleware. The only difference is
that `call()` of DummyA and DummyB returns modified string, and DummyC passes
execution to the next middleware. Now let's create and call stack that will call
DummyC first, then will call DummyB and will stop execution (see more samples in
_stacking.rb_):

``` ruby
app = DummyA.new
stack = [ proc {|app| DummyC.new app }, proc {|app| DummyB.new app } ]
puts stack.reverse.inject(app){ |a,e| e[a] }.call("FooBar")
```

This will produce following output:

```
Calling DummyC
Calling DummyB
foobar
```

Let's see what happens there. `stack` consist of two factories: first one
creates instance of DummyC middleware, second instance of DummyB. Now what
happens when we call `inject(app){ |a,e| e[a] }` on reversed stack:

* create instance of _DummyB_ with `app` passed to its constructor
* create instance of _DummyC_ with instance of middleware created on previous
  iteration (instance of _DummyB_)

So when we call `call("FooBar")` execution goes following way:

* DummyC.call
* DummyB.call

In other words. Decision to pass execution to the next middleware or not it
absolutely in the authority of current executed middleware. And middlewares are
stacked as Russian [matryoshka][4], so in the example above:

* DummyC's `@app` property points to instance of DummyB
* DummyB's `@app` property points to instance of DummyA
* DummyA's `@app` property is `nil`


### Map Middlewares

Finally! We got here! The topic that made me start this post. :)) The primitive
rackup file looks like this:

``` ruby
use Rack::CommonLogger
use Rack::Static, {:urls => %w{/css /images /js}, :root => 'public'}
run Application.new
```

According to knowledge from above, we can see that, request is first processed
by _CommonLogger_, then it's being processed by _Static_ which in it's turn
decides serve it by itself or pass execution down, and then (if _Static_
middleware passed execution) _Application_ receives a call request.

So the easiest way to "map" your middleware is when middleware supports some
kind of "URL map" limitations. According to example above, _Static_ middleware
basically can be something like this:

``` ruby
module Rack
  class Static
    def initialize(app, options = {})
      @app = app
      @urls = options[:urls]
      @root = options[:root]
    end

    def call(env)
      return @app.call(env) unless @urls.include? env["PATH_INFO"]
      # main processing goes here ...
    end
  end
end
```

That's the most easiest way. But there's alternative way, when middleware does
not provides such ability (e.g. `Rack::Directory`) - Builder's method `map()`.

> **NOTICE** In fact _Rack::Directory_ is not a middleware. It's an application.
> So you can't pass it to `use()` method. Middleware should accept instance of
> next aaplication or middleware as first argument of constructor.

This method creates an instance of _URLMap_ which in it's turn a special
middleware. So if you started to use `map()` you will need to define map for
default route as well, in other words, this won't work:

``` ruby
map "/blog" do
  run BlogApplication.new
end

run MainApplication.new
```

Instead you need to write it as:

``` ruby
map "/blog" do
  run BlogApplication.new
end

map "/" do
  run MainApplication.new
end
```

And here's why! First call of `map()` first of all creates instance of _URLMap_.
Also each `map()` attaches new instance of `Builder` with given block evaluated
under scope of its context. So if we will pretend that URLMap is just a hash of
_route => Builder instance_ pairs, then it would be something like this:

``` ruby
map["/blog"] = Builder.new(default_app) do
  run BlogApplication.new
end
```

When execution is passed to URLMap it will call appropriate Builder, e.g. in the
example above request to `/blog/foobar` will pass execution to `call()` method
of _BlogApplication_ instance and `env["PATH_INFO"]` will be `/foobar`.

That means that we can "bind" middlewares as follows in order to limit their
scope of responsibility:


``` ruby
use Rack::CommonLogger

# self here is an instance of first Builder

use "/downloads" do
  # self here is an instance of second Builder
  use SomeMiddleware, :root => 'public/downloads'
  run proc { [500, {"Content-Type"=>"text/plain"}, "Application Error"] }
end

map "/" do
  # self here is an instance of third Builder
  run Application.new
end
```

After all, take a look on [Builder's tutorial][5] for some other details and
info about how you can easily nest maps.


[1]: http://rack.rubyforge.org/
[2]: http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html
[3]: https://github.com/rack/rack/wiki/Tutorials
[4]: http://en.wikipedia.org/wiki/Matryoshka_doll
[5]: http://m.onkey.org/ruby-on-rack-2-the-builder
