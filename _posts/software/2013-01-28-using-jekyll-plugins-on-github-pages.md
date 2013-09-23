---
layout:    post
category:  software
tags:      [jekyll, plugins, github, publish]
title:     Using Jekyll plugins on GitHub Pages
---

Few people asked me how they can use [jekyll-assets][jekyll-assets] on [GitHub
pages][gh-pages]. There are [lots of info][google-info] out there on this topic,
but I would like to aggregate some kind of best practices here. Main thing to
understand here is that GitHub renders pages using [Jekyll][jekyll] with `safe`
mode enabled. Custom plugins are disabled when `safe` mode is on. In other words
this instruction applies to any third-party plugin...

[jekyll-assets]:  http://ixti.net/jekyll-assets/
[gh-pages]:       http://pages.github.com/
[google-info]:    https://www.google.com/search?q=github+pages
[jekyll]:         http://jekyllrb.com/

As I said above, GitHub Pages does not allows you to use custom plugins, so the
only way to use Jekyll with custom plugins on GitHub Pages is compiling sources
locally and pushing compiled results only. In other words, it becomes absolutely
indifferent where to publish your website GitHub Pages or any other hosting of
static files.

Following instructions are based on [Octopress][octopress] deployment how-to, so
all credits goes to community of that awesome project.

[octopress]: http://octopress.org/


### User & Organization Pages

User & Organization Pages live in a special repository dedicated to only the
Pages files. This repo must use `username/username.github.com` naming scheme.

GitHub will use `master` branch of such repo to build and publish the Pages.
That leads us into having `master` branch with compiled web-site and `source`
branch with our website sources.


#### Prepare repository

Repo preparation is very simple, just create a `source` branch in your repo:

    $ git checkout -b source master
    $ git push -u origin source

Now as you have created `source` branch you can make it _default_ on GitHub:

<div class="center">{% image 2013-01/github-repo-settings.png %}</div>


#### Automate publishing

Once repo is ready you can render your website and push compiled sources into
master branch. But doing it manually is a pain, so let's add simple rake task.
Create (if you don't have one yet) a Rakefile and add following into it:

``` ruby
require "rubygems"
require "tmpdir"

require "bundler/setup"
require "jekyll"


# Change your GitHub reponame
GITHUB_REPONAME = "ixti/ixti.github.com"


desc "Generate blog files"
task :generate do
  Jekyll::Site.new(Jekyll.configuration({
    "source"      => ".",
    "destination" => "_site"
  })).process
end


desc "Generate and publish blog to gh-pages"
task :publish => [:generate] do
  Dir.mktmpdir do |tmp|
    cp_r "_site/.", tmp
    Dir.chdir tmp
    system "git init"
    system "git add ."
    message = "Site updated at #{Time.now.utc}"
    system "git commit -m #{message.inspect}"
    system "git remote add origin git@github.com:#{GITHUB_REPONAME}.git"
    system "git push origin master --force"
  end
end
```

Now you can simply call `rake publish` to compile and publish your web-site to
GitHub Pages.


### Project Pages

Unlike User and Org Pages, Project Pages are kept in the same repo as the
project they are for. These pages are almost exactly the same as User and
Org Pages, with one main difference: `gh-pages` branch is used instead of
`master` to build and publish Pages.

There's no extra repo preapration steps needed. All that you'll need is a
similar, rake task with tiny changes in it:

``` ruby
require "rubygems"
require "tmpdir"

require "bundler/setup"
require "jekyll"


# Change your GitHub reponame
GITHUB_REPONAME = "ixti/jekyll-assets"


namespace :site do
  desc "Generate blog files"
  task :generate do
    Jekyll::Site.new(Jekyll.configuration({
      "source"      => ".",
      "destination" => "_site"
    })).process
  end


  desc "Generate and publish blog to gh-pages"
  task :publish => [:generate] do
    Dir.mktmpdir do |tmp|
      cp_r "_site/.", tmp
      Dir.chdir tmp
      system "git init"
      system "git add ."
      message = "Site updated at #{Time.now.utc}"
      system "git commit -m #{message.inspect}"
      system "git remote add origin git@github.com:#{GITHUB_REPONAME}.git"
      system "git push origin master:refs/heads/gh-pages --force"
    end
  end
end
```

Now you can run `rake site:publish` to compile and publish your web-site to
GitHub Pages. Take a look on [Jekyll's own Rakefile][jekyll-rakefile] as well
for alternative implementation of `rake site:publish`.

[jekyll-rakefile]: https://github.com/mojombo/jekyll/blob/master/Rakefile
