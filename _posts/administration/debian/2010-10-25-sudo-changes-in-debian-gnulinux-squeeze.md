---
layout:   post
category: administration/debian
tags:     debian authentication config policy sudo tty
title:    sudo changes in Debian GNU/Linux "squeeze"
---

If you have recently upgraded your (or dist-upgraded to) "squeeze", you might
noticed that `sudo` now works a little bit strange. It asks for a password too
often. Some people even thought it asks a password every-time now. That's
incorrect. Timeout was left same as it was before. But `tty_ticket` become `on`
by default...

To be honest, this is not related to Debian GNU/Linux at all. This change was
made by Todd C. Miller (author of [sudo][1]) on 2010-07-20, commit
[73dd2b82a3a9][2]. So now `tty_ticket` is on by default. That means that users
must authenticate on a per-tty basis. In other words, calling `sudo true` twice
on the same tty (or pts) will ask for a password only once. But it will ask
again (regardless to the timeout) on another tty.

In fact this is a great thing about sudo. But if you want to change default
behavior (to disable tty_ticket by default), you can simply put this line
into your `sudoers` file:

```
Defaults !tty_tickets
```

That's all. But think twice before disabling it by default.

[1]: http://www.sudo.ws/
[2]: http://www.sudo.ws/repos/sudo/rev/73dd2b82a3a9
