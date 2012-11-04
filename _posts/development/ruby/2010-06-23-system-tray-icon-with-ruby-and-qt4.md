---
layout:   post
category: development/ruby
tags:     qt ruby system-tray
title:    System tray icon with Ruby and QT4
---

In my previous post I have showed how to create a simple system tray icon in
ruby and GTK. Today, I will create exactly the same application but with QT4
instead of GTK... Before I started this, I was full of optimism that it will
be even easier to do this with QT. I was wrong :)) Because of some differences
it was not as easy as I wish it to be...

I was going to start with similar simple and really dumb example. But some
restrictions of QT disallowed me. So, to show a system tray icon, you need to
call `show` instance method. But before this, you must set `icon` instance
property, else it will throw a corresponding exception. So here's most simple
variant:

``` ruby
require 'Qt4'
app = Qt::Application.new(ARGV)
si  = Qt::SystemTrayIcon.new

si.icon = Qt::Icon.new('/path/to/some/image.png')
si.show

app.exec
```

There's no stock images like in GTK, at least I didn't found them, if you know -
let me know. According to QT's SDK there's `QIcon::fromTheme()` static method,
but unfortunately there's no corresponding one in qt4ruby. So we can skip step
with different types of icon image settings and go next. All snippets below will
assume that there are `app` and `si` initializations before, and `app.exec` call
after them. Now let's make our icon start|stop blinking on left click.

In QT all clicks (left, middle, right, etc) are handled by one signal -
`activated(QSystemTrayIcon::ActivationReason)`. Not the easiest name of the
signal to remember ;)) I spent about two hours trying to understand why SDK
says that `QStatusIcon` has `activated()` signal, but my app tells me that
there's no such signal. Anyway, finally I got it. Here's sample `activated()`
signal handler:

``` ruby
si.connect(SIGNAL('activated(QSystemTrayIcon::ActivationReason)')) do |reason|
  case reason
    when Qt::SystemTrayIcon::Trigger:       puts 'Left Click'
    when Qt::SystemTrayIcon::MiddleClick:   puts 'Middle Click'
    when Qt::SystemTrayIcon::Context:       puts 'Right Click'
    when Qt::SystemTrayIcon::DoubleClick:   puts 'Double Click'
    else
  end
end
```

There's also `Qt::SystemTrayIcon::Unknown` reason but this is not very useful
IMHO. After we figured out how and where we need to handle left click, let's
make icon blinking. You probably will be surprised, but it's not trivial as
with GTK. `Qt::SystemTrayIcon` don't have neither `blinking` instance property,
nor any single method to make it blink. So to make icon blink we need to create
a timer which will be replacing icon with empty one and restore original back
again every 0.5 second:

``` ruby
# define standard icon, alternative (blank) one and current state handler
std_icon = Qt::Icon.new('/path/to/some/image.png')
alt_icon = Qt::Icon.new
blinking = false

# assign default icon
si.icon  = std_icon
si.show

# run timer to swap icons every 0.5 second if blinking is true
Qt::Timer.new(app) do |timer|
  timer.connect(SIGNAL('timeout()')) do
    si.icon = (si.icon.isNull ? std_icon : alt_icon) if blinking
  end
  timer.start(500)
end

# finally assign left click handler
si.connect(SIGNAL('activated(QSystemTrayIcon::ActivationReason)')) do |reason|
  if Qt::SystemTrayIcon::Trigger == reason
    blinking = !blinking
    si.icon  = blinking ? alt_icon : std_icon
  end
end
```

OK. It was not as easy as with GTK, but still, it works :)) So now let's create
context menu with exit item. First of all we need to create a `Qt::Menu` and
populate it with `Qt::Action`s:

``` ruby
menu = Qt::Menu.new
quit = Qt::Action.new('&amp;Quit', menu)

quit.connect(SIGNAL(:triggered)) { app.quit }
menu.addAction(quit)
```

And now the most interesting part, as I told before QT's system tray icon
handles all clicks by one signal. But for context pop-up menu there's a special
instance property `contextMenu` exist. So to show a popup menu you need to
assign it with `menu` so it will be popped up on right click! But remember,
`activated(QSystemTrayIcon::ActivationReason)` will also be handled. So
following code will pop up a menu and will output _Right Click_ to the console:

``` ruby
si.contextMenu = menu

si.connect(SIGNAL('activated(QSystemTrayIcon::ActivationReason)')) do |reason|
  if Qt::SystemTrayIcon::Contex == treason
    puts 'Right Click'
  end
end
```

And now altogether again:

``` ruby
require 'Qt4'

app = Qt::Application.new(ARGV)
si  = Qt::SystemTrayIcon.new

std_icon = Qt::Icon.new('/path/to/some/image.png')
alt_icon = Qt::Icon.new
blinking = false

si.icon  = std_icon
si.show

Qt::Timer.new(app) do |timer|
  timer.connect(SIGNAL('timeout()')) do
    si.icon = (si.icon.isNull ? std_icon : alt_icon) if blinking
  end
  timer.start(500)
end

menu = Qt::Menu.new
quit = Qt::Action.new('&amp;Quit', menu)

quit.connect(SIGNAL(:triggered)) { app.quit }
menu.addAction(quit)

si.contextMenu = menu

si.connect(SIGNAL('activated(QSystemTrayIcon::ActivationReason)')) do |reason|
  case reason
    when Qt::SystemTrayIcon::Trigger
      blinking = !blinking
      si.icon  = blinking ? alt_icon : std_icon
    when Qt::SystemTrayIcon::MiddleClick:   puts 'Middle Click'
    when Qt::SystemTrayIcon::Context:       puts 'Right Click'
    when Qt::SystemTrayIcon::DoubleClick:   puts 'Double Click'
  end
end

app.exec
```


### Useful links:

* [qt4ruby homepage](http://rubyforge.org/projects/korundum/)
* [Qt4 Ruby Tutorial](http://techbase.kde.org/Development/Tutorials/Qt4_Ruby_Tutorial)
* [Qt::Timer example](http://stackoverflow.com/questions/313629/worker-threads-in-ruby)
