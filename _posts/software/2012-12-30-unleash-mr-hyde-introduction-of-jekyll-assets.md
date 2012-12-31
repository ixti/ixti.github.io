---
published: false
layout:    post
tags:      blog jekyll octopress plugin assets ruby
title:     Unleash Mr.Hyde! Introduction of Jekyll-Assets.
---

Not so long ago I have released [Jekyll-Assets][jekyll-assets] plugin, that adds
Rails-alike assets pipeline for [Jekyll][jekyll] or [Octopress][octopress]
powered blogs. That means when enabled, you can write your assets in languages
like CoffeeScript, SASS, LESS, automagically minify and concatenate assets, and
few things more ;)) So this is an introduction on some of core features and how
to enable jekyll-assets for your blog...

[jekyll-assets]:  http://ixti.net/jekyll-assets/
[jekyll]:         http://jekyllrb.com/
[otopress]:       http://octopress.org/

As I said before jekyll-assets is a plug-in for Jekyll and Octopress. Setup
process is the same for both of them, so following examples will be with
Jekyll-based blog, but instructions are quiet similar for Octopress users with
few differences in "default" paths you have to use.

For visual demonstration I'll be using an [example blog][example]. It is under
git control, so you can always see [history][history] of it's evolution.

[example]: https://github.com/ixti/jekyll-assets-demo
[history]: https://github.com/ixti/jekyll-assets-demo/commits/master

To make demonstration more realistic, let's define what are we going to get at
the end. We are going to add a nice-looking [carousel][bootstrap-carousel] from
[Bootstrap][bootstrap] framework. And we are going to have symbols font
generated with [Fontello][fontello] to have links to our Twitter, GitHub and
LinkedIN profiles as vector icons. Also we are going to write all our own
javascript assets with [CoffeeScript][coffee-script].

[bootstrap-carousel]:   http://twitter.github.com/bootstrap/javascript.html#carousel
[bootstrap]:            http://twitter.github.com/bootstrap/
[fontello]:             http://fontello.com/
[coffee-script]:        http://coffeescript.org/


### Preparations

As we are going to have our javascript assets to be written in CoffeeScript and
all stylesheets and javascripts to be minified at the end, we will need
[ExecJS][execjs]-supported runtime on system to invoke it.

That means that you'll need to have [Node][node.js] and CoffeeScript Node module
installed. Also, probably, you would like to have [UglifyJS][uglifier] Node
module installed as well to have _minification_ (alternatively you might want to
use YUI compressor for this purpose).

[execjs]:   https://github.com/sstephenson/execjs
[node.js]:  http://nodejs.org/
[uglifier]: https://github.com/mishoo/UglifyJS


### Initial state

Before we start, let's overview [initial structure][step-0] of our blog:

    % tree -F --charset=UTF8
    .
    ├── Gemfile
    ├── Gemfile.lock
    ├── index.html
    ├── _layouts/
    │   ├── default.html
    │   └── post.html
    ├── _posts/
    │   └── 2012-12-30-hello-world.md
    ├── README.md
    └── _site/
        ├── 2012/
        │   └── 12/
        │       └── 30/
        │           └── hello-world.html
        ├── Gemfile
        ├── Gemfile.lock
        └── index.html

    6 directories, 11 files


### Installation

First of all we'll need to add some gems into `Gemfile`:

``` ruby
#
# jekyll-assets plugin itself
#

gem "jekyll-assets"

#
# Additional gems for jekyll-assets
#

gem "coffee-script" # We want to write our javascripts in CoffeeScript
gem "uglifier"      # And we want our javascripts to be minified with UglifyJS
gem "sass"          # And we want to write our stylesheets using SCSS/SASS
```

Let's slow down and take a closer look on the required gems:

* `jekyll-assets`: This is plug-in itself, nothing to say more
* `coffee-script`: This gem will allow us to write javascripts using
  CoffeeScript language
* `uglifier`: This gem will allow us to use UglifyJS for compiled javascripts
  minification
* `sass`: This gem will allow us to write our stylesheets using SASS or SCSS and
  also it will allow us compress our compiled stylesheets.

After you have put these lines into your `Gemfile`, run `bundle` to install
dependencies. Now you are ready to enable plug-in. That's really simple, just
add following line into your `_plugins/ext.rb` file (create it if you don't have
such one yet):

``` ruby
require "jekyll-assets"
```

That's all. [Installation][step-1] is complete. Now let's add some assets.


### Add some basic assets

By default, jekyll-assets will search for assets under following self-describing
paths (relative to your sources root):

* `_assets/images/`
* `_assets/stylesheets/`
* `_assets/javascripts/`

So let's create these directories and some base assets. First of all we will put
`noise.png` (nice background lovely generated with [noise generator][noise-gen])
under `_assets/images` directory. After we will add `app.css.sass` under our
`_assets/stylesheets` directory with following contents:

[noise-gen]: http://www.noisetexturegenerator.com/

``` sass
body
  background-image: url(asset_path("noise.png"))
```

Notice that despite the fact that `noise.png` is kept under different directory
we refer it using so-called "logical path" which is relative to the paths where
jekyll-assets will look for assets. Now let's also create our `app.js.coffee`
under `_assets/javascripts` with something ridiculous, but that will help us
easily understand that we've done everything correctly. So here's what we'll put
into our main javascript file.

``` coffeescript
alert "It works!"
```

So now, we can say that we have [following structure][step-2] of assets:

    % tree -F --charset=UTF8 ./_assets/
    ./_assets/
    ├── images/
    │   └── noise.png
    ├── javascripts/
    │   └── app.js.coffee
    └── stylesheets/
        └── app.css.sass

    3 directories, 3 files


##### Using assets

Once our assets are ready, let's add `<link>` and `<script>` tags into our
layout file. So our `<head>` will look like this:

``` html
  <head>
    <title>My Simple Blog</title>
    {% stylesheet app %}
    {% javascript app %}
  </head>
```

Notice, that we may avoid file extension when we use `stylesheet` or
`javascript` liquid tags, so the above is shorthand syntax to:

``` html
  <head>
    <title>My Simple Blog</title>
    {% stylesheet app.css %}
    {% javascript app.js %}
  </head>
```

Also, notice, that despite that our asset files are in fact have `.coffee`
extension, we call this file as `app.js` anyway. So we can say that we use
"logical" extension. To better understand this concept, all these files will be
treated as `foobar.js`:

    foobar.js.coffee
    foobar.js.coffee.erb
    foobar.coffee
    foobar.coffee.erb

Same thing about `*.css`. This is so called pipeline. So file
`foobar.js.coffee.erb` will be first rendered with _ERB_, then it will be
compiled with CoffeeScript. And CoffeeScript is a JavaScript type, so we
can avoid `.js` extension, but we leave it for readability.

Here's list of Liquid tags you may want to use in your templates:

* `{% javascript <asset> %}`: Generates `<script>` tag for given asset
* `{% stylesheet <asset> %}`: Generates `<link rel="stylesheet">` tag for given
  asset
* `{% asset_path <asset> %}`: Generates URL for an asset. Useful for images,
  e.g.: `<img src="{% asset_path me.jpg %}" alt="Alexey Zapparov" />`
* `{% asset <asset> %}`: Returns compiled source of an asset. For example you
  can use it to _embed_ some asset, e.g. [Modernizr][modernizr].

[modernizr]: http://modernizr.com/


##### Helpers available inside assets

You can use following helpers/methods inside your ERB, SASS and SCSS files:

* `asset_data_uri(asset_logical_name)`: Returns encoded Base64 data URI. Use it
  to embed images into your stylesheets.
* `asset_path(asset_logical_name)`: Returns URL of compiled asset.

You have also MIME-type specific versions of `asset_path`, such as:

* `image_path`
* `audio_path`
* `video_path`
* `font_path`
* `stylesheet_path`
* `javascript_path`


### Add vendors

It's time to add some more assets. I don't wanna mess my own assets with vendors
so I'm gonna create a `_assets/vendor` directory and put all vendor assets
there. I'll show how to make plugin respect custom directories later. And here's
a brief overview of my [assets now][step-3]:

    % tree -F -L 2 --charset=UTF8 ./_assets/
    ./_assets/
    ├── images/
    │   └── noise.png
    ├── javascripts/
    │   └── app.js.coffee
    ├── stylesheets/
    │   └── app.css.sass
    └── vendor/
        ├── bootstrap/
        ├── fontello/
        ├── jquery.js
        └── modernizr.js

    6 directories, 5 files

So `bootstrap/` contains unpacked [Bootstrap in SASS][bootstrap-sass] zipball,
`fontello/` contains custom generated symbol font and jQuery with Modernizr is
just what it look like :D

[bootstrap-sass]: https://github.com/jlong/sass-twitter-bootstrap/


### Configure

It's time to configure plug-in a little bit. As we added vendor assets under
specific directory we will need to add it to the list of assets paths:

``` yaml
assets:
  sources:
    - _assets/images/
    - _assets/javascripts/
    - _assets/stylesheets/
    - _assets/vendor/
```

Notice that all plug-in specific configuration options are kept under `assets`
section. Let's also specify that we want to have compression enabled, so that
our config file might look like:

``` yaml
assets:
  sources:
    - _assets/images/
    - _assets/javascripts/
    - _assets/stylesheets/
    - _assets/vendor/
  compress:
    css:  sass
    js:   uglifier
```

OK. Now, when we have [everything prepared][step-4], we are ready to start
working with our assets...


[step-0]: https://github.com/ixti/jekyll-assets-demo/tree/9880a5074fdf7cbb13a156045275abf0b3ce3861
[step-1]: https://github.com/ixti/jekyll-assets-demo/tree/370c683dcd88b9cdee5f14f497ce5ac72c3e1d77
[step-2]: https://github.com/ixti/jekyll-assets-demo/tree/3c29aaca28a7fe66a591b37bf1c01349590071f8
[step-3]: https://github.com/ixti/jekyll-assets-demo/tree/b12bbb28fe98039e4fa97a3676885e2b850f1194
[step-4]: https://github.com/ixti/jekyll-assets-demo/tree/677f951cad2fff4e4ad950741dc1b0ffcc28c96a
