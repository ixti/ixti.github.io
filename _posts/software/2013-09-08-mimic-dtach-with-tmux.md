---
layout:    post
title:     Mimic dtach with tmux
category:  software
tags:      [dtach, tmux, screen, detach]
---

[dtach][1] is a tiny program that emulates detach feature of [screen][2]. You
can use it to run, for example [WeeChat][3] in background without suspending it.
And [tmux][4] is an awesome feature-rich alternative to screen. So why one would
want to use tmux in place of dtach? Personally I do because it allows to change
X window title, thus I can make sure WeeChat is always opened on 8th workspace
in my XMonad without any extra hacks.

So let's summarize what I want from tmux:

- no history
- no hotkeys expect the one to "detach"
- no status line

To achieve that I'm gonna create a config for tmux and a launcher something like
this:

``` sh
#!/bin/sh
# file ~/.local/bin/weechat
tmux start
tmux -f ~/.tmux/weechat.conf new -d -A -s weechat weechat-curses \; attach
```

Pretty simple enough, now all we need is a config for tmux:

```
# Unbind default prefix, so that there will be no hotkeys available and bind
# hotkeys we are interested in:

unbind C-b

bind-key -n C-\   detach
bind-key -n C-F10 kill-session


# Disable (hide) status line completely

set-option -g status off


# Force tmux to resize a window based on the smallest client actually
# viewing it, not on the smallest one attached to the entire session.

set-window-option -g aggressive-resize on


# 256 Colours

set-option -g default-terminal "screen-256color"


# Set history limit

set-option -g history-limit 0


# Window titling for X

set-option -g set-titles on
set-option -g set-titles-string '#W'
```


And that's all. To simplify this process I've released a Ruby gem [dmux][5].
Alternatively you can (if you by some reason aware of Ruby) use initial Shell
script of mine:

``` sh
{% asset 2013-09/dmux.sh %}
```

Just save it as `dmux` somewhere within your `$PATH` environment variable and
don't forget to `chmod +x` it.


[1]: http://dtach.sourceforge.net/
[2]: http://www.gnu.org/software/screen/
[3]: http://www.weechat.org/
[4]: http://tmux.sourceforge.net/
[5]: https://rubygems.org/gems/dmux
