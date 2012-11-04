---
layout:   post
category: development
tags:     how-to git checkout submodule
title:    Synchronized checkouts of git submodules upon main repo branch change
---

This tip will be useless for most of all. But if you are involved in porting of
something to something better (or at least something you get paid for), for
example porting project from [LESS][1] to [SASS][2]. Well you don't need anything
special for such purpose, but the problem comes out when you want to have exact
copy of original repo (with different branches), but with ported sources.

The best explanation of a problem is [my port][3] of [Twitter's Bootstrap][4]
CSS framework. As you can see, I'm trying to make my _bootstrap.scss_ exactly
match original sources, but written in _SASS_. Also I want to have two branches:
`master` and `2.0-wip` and keep work on both within same repo, just like
original repo does.

To track changes in original repo more easily, I have decided to add it as a
submodule to my repo. And created branches (I wanted to work on) with same names
as original ones. So it was something like this:

```
ixti@msi:~/demo$ git submodule add git://github.com/twitter/bootstrap.git ./src
Cloning into src...
remote: Counting objects: 4664, done.
remote: Compressing objects: 100% (1728/1728), done.
remote: Total 4664 (delta 3046), reused 4408 (delta 2837)
Receiving objects: 100% (4664/4664), 1.20 MiB | 534 KiB/s, done.
Resolving deltas: 100% (3046/3046), done.

ixti@msi:~/demo$ git commit -m 'Added original repo as submodule'
[master 5871d81] Added original repo as submodule
 2 files changed, 4 insertions(+), 0 deletions(-)
 create mode 100644 .gitmodules
 create mode 160000 src

ixti@msi:~/demo$ cd src && git branch -a && cd ..
* master
  remotes/origin/2.0-wip
  remotes/origin/HEAD -> origin/master
  remotes/origin/dev
  remotes/origin/gh-pages
  remotes/origin/kasperp-dropdown-btn-dev
  remotes/origin/master

ixti@msi:~/demo$ git checkout -b 2.0-wip
Switched to a new branch '2.0-wip'

ixti@msi:~/demo$ cd src && git checkout 2.0-wip && cd ..
Branch 2.0-wip set up to track remote branch 2.0-wip from origin.
Switched to a new branch '2.0-wip'

ixti@msi:~/demo$ git commit -am 'Initial start of 2.0-wip branch'
[2.0-wip 659720a] Initial start of 2.0-wip branch
 1 files changed, 1 insertions(+), 1 deletions(-)
```

Everything is cool, except one annoying thing - `src` does not tracks your
checkouts in main repo, so when you will checkout to the master branch in your
repo, it will tell you that `src` is modified, so you'll need to manually check
it out:

```
ixti@msi:~/demo$ git checkout master
M   src
Switched to branch 'master'

ixti@msi:~/demo$ cd src && git checkout master && cd ..
Switched to branch 'master'

ixti@msi:~/demo$ git status 
# On branch master
nothing to commit (working directory clean)
```

Fortunately we can automatize this pain with this simple `post-checkout` hook:

``` bash
#!/bin/sh
#file: .git/hooks/post-checkout

# Get active branch name after checkout
BRANCH=$(git branch | grep '^*' | cut -b 3-)

# Silently exit when checked out on specific commit (no branch)
if [ "x(no branch)" = "x$BRANCH" ] ; then exit 0; fi

# Get into our submodule with original repo
cd src

# Silently exit when original repo has no similarly named branch
git branch | grep "$BRANCH" -q || exit 0

# Checkout original repo to be on same branch as we are
git checkout $BRANCH
```

In order to use it, just put it into your `$GIT_DIR/hooks/` directory
(normally it will be `.git/hooks/` under root directory of your repo).

For more details on hooks, please `man githooks`. Also you might find useful
reading [ProGit][5] and [Git Book][6] about hooks.

[1]: http://lesscss.org/
[2]: http://sass-lang.com/
[3]: https://github.com/ixti/bootstrap.scss
[4]: http://twitter.github.com/bootstrap/
[5]: http://progit.org/book/ch7-3.html
[6]: http://book.git-scm.com/5_git_hooks.html
