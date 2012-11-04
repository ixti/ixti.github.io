---
layout:   post
category: development/ruby
tags:     gtk ruby system-tray
title:    System tray icon with Ruby and GTK2
---

Everybody knows what system tray is. My friends (Hello, bigote and stanislavv!)
were suggesting to start using FVWM and it's pager instead of using system tray.
But I was not inspired by pager. Probably because I was too lazy to try it in
action for more than 1 minute. Anyway. One day I realized that I need something
to notify me via system tray icon. So today I'm going to create a simple system
tray icon in ruby with GTK step by step...

First of all let's create a really simple (and absolutely dumb) version, which
will only create a new system tray icon:

``` ruby
require 'gtk2'
Gtk::StatusIcon.new
Gtk.main
```

As you can see, first line `require 'gtk2'` include GTK bindings. Then we
creating a new instance of `Gtk::StatusIcon`. And finally run main GTK loop with
`Gtk.main`. So basically first and the last lines are not very interesting and
all following code snippets will be without these two lines to keep you focused
on things that are really important ;)) But don't forget them when you'll be
trying these snippets...

If you tried the snippet above, you might notice that it adds a blank icon into
system tray. Looks at least strange, so let's add some image to it. With GTK you
can use stock image, by setting `stock` instance property of `StatusIcon`:

``` ruby
si        = Gtk::StatusIcon.new
si.stock  = Gtk::Stock::DIALOG_INFO
```

Or you can you your own custom image by setting `pixbuf` instance property:

``` ruby
si        = Gtk::StatusIcon.new
si.pixbuf = Gdk::Pixbuf.new('/path/to/some/image.png')
```

You can specify both `stock` and `pixbuf` - but only the last one will be used.
So:

``` ruby
si        = Gtk::StatusIcon.new
si.pixbuf = Gdk::Pixbuf.new('/path/to/some/image.png')
si.stock  = Gtk::Stock::DIALOG_INFO
```

Will initiate a system tray icon with `Gtk::Stock::DIALOG_INFO` stock image.

Now, when out system tray icon has a nice looking image, let's add some
funkiness. Let's make icon start blinking on left clicking it, and stop on
clicking it again. To make icon blink, you need to set `blinking` instance
property to `true`, e.g.:

``` ruby
si.blinking = true
```

But we want it to be turned on|off mouse left click. To do so, we need to
connect an `activate` signal:

``` ruby
si.signal_connect('activate'){ |icon| icon.blinking = !(icon.blinking?) }
```

Cool! Now it's cool! But don't stop. Let's add a pop-up menu for mouse right
clicking. To handle right click you need to use `popup-menu` signal, something
like this:

``` ruby
si.signal_connect('popup-menu') do |tray, button, time|
  # something to do?
end
```

Creating a popup-menu is little bit out of the scope, but to accomplish my first
system tray idiotic application, I will show it too. First, we need to create a
`Gtk::Menu` instance:

``` ruby
menu = Gtk::Menu.new
```

Fill it with items, call `show_all` instance method, and call `popup` method
when we need it to be popped up. Now let's create a new item quit item, make it
call `Gtk.main_quit` on click, and append it to the menu:

``` ruby
menu = Gtk::Menu.new
quit = Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)

quit.signal_connect('activate'){ Gtk.main_quit }
menu.append(quit)
menu.show_all
```

So all we need no is to call `menu.popup` inside `popup-menu` signal handler:

``` ruby
si.signal_connect('popup-menu') do |icon, button, time|
  menu.popup(nil, nil, button, time)
end
```

And altogether now:

``` ruby
require 'gtk2'

si        = Gtk::StatusIcon.new
si.stock  = Gtk::Stock::DIALOG_INFO

si.signal_connect('activate'){ |icon| icon.blinking = !(icon.blinking?) }

menu = Gtk::Menu.new
quit = Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)

quit.signal_connect('activate'){ Gtk.main_quit }
menu.append(quit)
menu.show_all

si.signal_connect('popup-menu') do |icon, button, time|
  menu.popup(nil, nil, button, time)
end

Gtk.main
```

After all, I want to thank Vincent Carmona, whose example was a vivid tutorial
of how to make a much smarter (than mine) system tray icon with GTK and ruby.
You will find his example as an attachment to this post. I recommend you to
read it, if you are still reading this ;))


### Useful links:

* [Gtk::StatusIcon documentation](http://ruby-gnome2.sourceforge.jp/hiki.cgi?cmd=view&p=Gtk::StatusIcon)
* [Vincent Carmona's example](http://ruby-gnome2.sourceforge.jp/hiki.cgi?StatusIcon+example#StatusIcon+example)
