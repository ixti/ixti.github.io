---
layout:    post
title:     XMonad.Action.GridSelect spawnSelected with nice titles
category:  software
tags:      [XMonad, menu, spawn, grid, snippet, haskell]
---

There's an awesome module available for [XMonad][1] called [GridSelect][2]. It
contains very pretty window selectors and such. And one of it's awesome
functions is `spawnSelected` that aimed to build a grid menu with apps to run.
Usage is pretty simple: `spawnSelected conf ["xterm", "smplayer", "gvim"]`.
But what if you want to have *nice* titles rather than command names?

If you'll take a look on that function [source][3] it zips given list with
itself and feeds to `gridlist` function, which returns `snd` element of chosen
tuple. That means you can easily write your own definitions that will allow to
provide nice names for menu elements. So it will look something like this:

<div class="center">
  <img src="{% asset_path posts/2013-09/modified-spawnselected.png %}"
       alt="spawnSelected' in action screenshot" />
</div>

Let's import module first:

``` haskell
import XMonad.Actions.GridSelect
```

Then we can define our version of `spawnSelected` like this:

``` haskell
spawnSelected' :: [(String, String)] -> X ()
spawnSelected' lst = gridselect conf lst >>= flip whenJust spawn
  where conf = defaultGSConfig
```

Now all you need to do is to add a hotkey to run your menu, something like this:

``` haskell
, ((modm, xK_r), spawnSelected'
  [ ("Mozilla Firefox", "firefox")
  , ("GVim",            "gvim")
  , ("MCabber",         "xterm -e detach -A /tmp/mcabber -z mcabber")
  , ("WeeChat",         "xterm -e detach -A /tmp/weechat -z weechat-curses")
  , ("Terminal",        "xterm")
  ])
```


[1]: http://xmonad.org
[2]: http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-GridSelect.html
[3]: http://xmonad.org/xmonad-docs/xmonad-contrib/src/XMonad-Actions-GridSelect.html#spawnSelected
