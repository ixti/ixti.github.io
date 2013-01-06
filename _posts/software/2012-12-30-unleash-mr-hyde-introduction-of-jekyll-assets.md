---
layout:    post
tags:      blog jekyll octopress plugin assets ruby
title:     Unleash Mr.Hyde! Introduction of Jekyll-Assets.
---

Not so long ago I have released [Jekyll-Assets][jekyll-assets] plugin, that adds
Rails-alike assets pipeline for [Jekyll][jekyll] or [Octopress][octopress]
powered blogs. As later [Brandon Mathis mentioned][imathis], a reference to
"rails-alike" gives almost zero understanding of what plugin actually does. In
few words, with this plugin you can write your assets in languages like
CoffeeScript, SASS, LESS, automagically minify and concatenate assets,
and more ;)) So this is an introduction to some of core features and
how to enable jekyll-assets for your blog...

[jekyll-assets]:  http://ixti.net/jekyll-assets/
[jekyll]:         http://jekyllrb.com/
[otopress]:       http://octopress.org/
[imathis]:        https://twitter.com/imathis/status/284089936884420608

As I said before jekyll-assets is a plug-in for Jekyll and Octopress. Setup
process is the same for both of them, so examples will be shown on a
Jekyll-based blog, but instructions are quiet similar for Octopress users with
few differences in "default" paths you have to use.

For visual demonstration I'll be using an [example blog][example]. It is under
git control, so you can always see [history][history] of it's evolution.

[example]: https://github.com/ixti/jekyll-assets-demo
[history]: https://github.com/ixti/jekyll-assets-demo/commits/master

First of all let's take a quick look at what we are going to do. Assume we have
a [very simple blog][step-0] with some posts. And we're gonna style it up with
[Twitter's Bootstrap][bootstrap] framework. And we are going to add some search
by tags feature using [typeahead][bootstrap-typeahead] [jQuery][jquery] plugin
from Bootstraps' toolbox. Also we are going to write our own assets in
[SASS][sass] and [CoffeeScript][coffee-script].

[bootstrap-typeahead]:  http://twitter.github.com/bootstrap/javascript.html#typeahead
[bootstrap]:            http://twitter.github.com/bootstrap/
[jquery]:               http://jquery.com/
[sass]:                 http://sass-lang.com/
[coffee-script]:        http://coffeescript.org/


### Preparations

As we are going to have our javascript assets to be written in CoffeeScript and,
we will need [ExecJS][execjs]-supported runtime on system to invoke it.

That means that you'll need to have [Node][node.js] and CoffeeScript Node module
installed. Also, probably, you would like to have [UglifyJS][uglifier] Node
module installed as well to have _minification_ (alternatively you can use YUI
compressor for this purpose).

[execjs]:   https://github.com/sstephenson/execjs
[node.js]:  http://nodejs.org/
[uglifier]: https://github.com/mishoo/UglifyJS


### Initial state

Before we start, let's overview [initial structure][step-0] of our blog:

    .
    ├── _assets/
    │   └── javascripts/
    │       └── vendor/
    ├── _config.yml
    ├── Gemfile
    ├── Gemfile.lock
    ├── index.html
    ├── _layouts/
    │   ├── default.html
    │   └── post.html
    ├── _posts/
    │   ├── 2012-01-18-it-s-the-final-countdown-the-only.md
    │   └── ...
    └── README.md


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

Let's slow down and take a closer look on the required gems above:

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

That's all. Installation is complete. Now let's add some assets.


### Some basic assets

By default, jekyll-assets will search for assets under following self-describing
paths (relative to your sources root):

* `_assets/images/`
* `_assets/stylesheets/`
* `_assets/javascripts/`

So let's create these directories and some base assets.

First of all we will put `noise.png` (nice background lovely generated with
[noise generator][noise-gen]) under `_assets/images` directory.

[noise-gen]: http://www.noisetexturegenerator.com/

Now let's add some vendors:

- we'll save jQuery as `_assets/javascripts/vendor/jquery.js`
- and [Modernizr][modernizr] as `_assets/javascripts/vendor/modernizr.js`
- and all SASS files of [SASS port of Bootstrap][bootstrap-sass]
  under `_assets/stylesheets/vendor/bootstrap` directory.

[modernizr]:      http://modernizr.com/
[bootstrap-sass]: https://github.com/jlong/sass-twitter-bootstrap

OK. Now let's ~~put a smile on that face~~ style our blog a little bit. To do so
we'll create a simple `_assets/stylesheets/app.css.sass` file first with
something like this:

``` sass
body
  background-color: #eee
  background-image: url(image_path('noise.png'))
```

Notice that despite the fact that `noise.png` is kept under different directory
we refer it using so-called "logical path" which is relative to the paths where
jekyll-assets will look for assets. Let's include bootstrap, the easiest way
would be to add a line like this one to the op of our main stylesheet file:

``` sass
//= require vendor/bootstrap/bootstrap
```

But first of all that looks ugly, secondly, we don't need "full" bootstrap. So
we will require `vendor/bootstrap` instead, will create this file as
`_assets/stylesheets/vendor/bootstrap.css.scss` and will include only those
parts we interested in:

``` sass
@import "bootstrap/variables";
@import "bootstrap/mixins";

// CSS Reset
@import "bootstrap/reset";

// Grid system and page structure
@import "bootstrap/scaffolding";
@import "bootstrap/layouts";

// Base CSS
@import "bootstrap/type";
@import "bootstrap/forms";

// Components: common
@import "bootstrap/dropdowns";

// Components: Nav
@import "bootstrap/navs";
@import "bootstrap/navbar";

// Components: Misc
@import "bootstrap/labels-badges";

// Utility classes
@import "bootstrap/utilities";
```

So, let's mixin helpers of Bootstrap into our main stylesheet and make it even
more funky. Here's what our `app.css.sass` will look like after all:

``` sass
//= require vendor/bootstrap


@import "vendor/bootstrap/mixins"


body
  background-color: #eee
  background-image: url(image_path('noise.png'))


#content
  background-color: #fff
  border: 1px solid #ccc

  @include border-radius(6px)
  @include box-shadow(0 1px 3px rgba(0,0,0,.1))

  margin: 25px auto
  padding: 25px
  width: 940px


#js-tag-search
  display: none


.js
  body
    @include opacity(0)

    &.is-ready
      @include opacity(100)
      @include transition(opacity 1s)

  #js-tag-search
    display: block
```

Now, when our styles are ready, let's add some basic JavaScript file as well.
Let's create `_assets/javascripts/app.js.coffee` with following content:

``` coffeescript
#= require vendor/jquery

$ ->
  $("body").addClass "is-ready"
```

Hooray! We're [ready][step-1] to use these assets in our layout. But before
we'll continue here's an overview of our assets:

    ./_assets/
    ├── images/
    │   └── noise.png
    ├── javascripts/
    │   ├── app.js.coffee.erb
    │   └── vendor/
    │       ├── jquery.js
    │       └── modernizr.js
    └── stylesheets/
        ├── app.css.sass
        └── vendor/
            ├── bootstrap/
            │   ├── _accordion.scss
            │   └── ...
            └── bootstrap.css.scss


##### Using assets

Here's how our layout will look like:

{% raw %}
``` html
<!DOCTYPE html>
<html>
  <head>
    <title>My Blog</title>
    {% stylesheet app %}
    <script type="text/javascript">{% asset vendor/modernizr %}</script>
  </head>
  <body>
    <div id="content">
      <div class="container">
        {{ content }}
      </div>
    </div>

    {% javascript app %}
  </body>
</html>
```
{% endraw %}

I believe that this example is simple enough to understand, but here'a a quick
overview of what is happening there:

- {% raw %}`{% stylesheet app %}`{% endraw %}
  will generate a `<link>` tag with URL to our `app.css`
  (`_assets/stylesheets/app.css.sass`)
- {% raw %}`{% asset vendor/modernizr %}`{% endraw %}
  will return compiled body of `vendor/modernizr`
  (`_assets/javascripts/vendor/modernizr.js`)
- {% raw %}`{% javascript app %}`{% endraw %}
  will generate `<script>` tag with URL to our `app.js`
  (`_assets/javascripts/app.js.coffee`)

Notice, that we may avoid file extension when we use `stylesheet` or
`javascript` liquid tags, so the above are shortcuts for:

- {% raw %}`{% stylesheet app.css %}`{% endraw %}
- {% raw %}`{% javascript app.js %}`{% endraw %}

Also, notice, that despite that our asset files are in fact have `.coffee`
extension, we call this file as `app.js` anyway. So we can say that we use
"logical" extension. To better understand this concept, all these files will be
treated as `foobar.js`:

    foobar.js.coffee
    foobar.js.coffee.erb
    foobar.coffee
    foobar.coffee.erb

Same thing about `*.css`. This is so called pipeline. So `foobar.js.coffee.erb`
will be first rendered with _ERB_, then it will be compiled with CoffeeScript.
And CoffeeScript is a JavaScript type, so we can avoid `.js` extension, but we
leave it for readability.

Here's list of Liquid tags you might want to use in your templates:

- {% raw %}`{% javascript <asset> %}`{% endraw %}:
  Generates `<script>` tag for given asset
- {% raw %}`{% stylesheet <asset> %}`{% endraw %}:
  Generates `<link rel="stylesheet">` tag for given asset
- {% raw %}`{% asset_path <asset> %}`{% endraw %}:
  Generates URL for an asset. Useful for images, e.g.
  {% raw %}`<img src="{% asset_path me.jpg %}" alt="Alexey V Zapparov" />`{% endraw %}
- {% raw %}`{% asset <asset> %}`{% endraw %}:
  Returns compiled source of an asset. You can use it to _embed_ some asset,
  e.g. Modernizr.


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


### Let's go crazy now!

As final step with asets let's make our `app.js` more dynamic and add list of
our posts with inks, titles and tags to allow search throught them with
JavaScript. For such crazy thing you will need ERB, rename `app.js.coffee` to
`app.js.coffee.erb` and now you can write something like this inside of it:

``` coffeescript
console.log <%= JSON.dump site.posts.map { |p| p.to_liquid["title"] } %>
```

Notice, that to use `JSON` you will ned to require it first. It's a standard
Ruby library s no need for extra step despite adding follwoing line into your
`_plugins/ext.rb` file:

``` ruby
require "json"
```

Enough talking, let's create something useful. We'll add a navigation bar (from
Bootstrap) with search field into our layout like so:

``` html
<div class="navbar navbar-static-top">
  <div class="navbar-inner">
    <div class="container">
      <a href="/" class="brand">My Blog</a>

      <form id="js-tag-search" class="form-search navbar-form pull-right">
        <input type="text" class="input-medium search-query"
               placeholder="Type tags to search" />
      </form>
    </div>
  </div>
</div>
```

Similar to stylesheets, we will save all jQuery plugins from Bootstrap into
`_assets/javascripts/vendor/bootstrap`:

    ./_assets/
    ├── images/
    │   └── noise.png
    ├── javascripts/
    │   ├── app.js.coffee.erb
    │   └── vendor/
    │       ├── bootstrap/
    │       │   ├── bootstrap-affix.js
    │       │   └── ...
    │       ├── jquery.js
    │       └── modernizr.js
    └── stylesheets/
        ├── app.css.sass
        └── vendor/
            ├── bootstrap/
            │   ├── _accordion.scss
            │   └── ...
            └── bootstrap.css.scss

Then we'll add `require bootstrap-typeahead` directive into our main file with
some initialization code, and finally our `app.js.coffee.erb` will look like:

``` coffeescript
#= require vendor/jquery
#= require vendor/bootstrap/bootstrap-typeahead

$ ->
  $("body").addClass "is-ready"

  $("#js-tag-search input").typeahead
    source: <%=
      JSON.dump site.posts.map { |p|
        [p.to_liquid["title"], p.url, p.tags.join(",")]
      }
    %>
    sorter: (items) ->
      $.map items, (o) ->
        JSON.stringify o
    matcher: (item) ->
      0 <= item[2].indexOf @query
    updater: (item) ->
      item = JSON.parse item
      window.location = item[1]
      null
    highlighter: (item) ->
      item = JSON.parse item
      "<a href=\"#{item[1]}\">#{item[0]}</a>"
```

That's all! You can start jekyll server now to [see it][step-2] in action.


### The world is not enough

It's time to say jekyll-assets to minify our compiled assets. It's as easy
as [adding few lines][step-3] into your `_config.yml` file:

``` yaml
assets:
  compress:
    css:  sass
    js:   uglifier
```

For detailed information about possible configuration options refer
[jekyll-assets][jekyll-assets] or contact me.


[step-0]: https://github.com/ixti/jekyll-assets-demo/commit/111b2ae15550f6654be31291eb9e578c59272d57
[step-1]: https://github.com/ixti/jekyll-assets-demo/commit/06e4c46c841e51d8e4b465527a84cdb635313f19
[step-2]: https://github.com/ixti/jekyll-assets-demo/commit/c6303d783bf1ac2bfcea6654ddcebd68b787e50a
[step-3]: https://github.com/ixti/jekyll-assets-demo/commit/3152ff5cb0ee19b663abd20d4d118faedd84d5fd
