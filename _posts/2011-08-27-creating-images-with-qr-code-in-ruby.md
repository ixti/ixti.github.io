---
layout:   post
category: development/ruby
tags:     ruby qr code rmagick
title:    Creating images with QR code in Ruby
---

Don't know why but recently I have decided that I want to have a [QR code][1]
with URL on each page of my blog that will be visible on printer-only variant of
blog. Unfortunately after I have prepared a proof of concept version, I realized
that in fact I don't need it, and most likely nobody will need it, at least on
my blog. But just for historic reasons I want to share my experience. I hope it
will be helpful for at least somebody.

For those of you who don't know what is QR code, here's what [Wikipedia][2]
says:

> A QR code (abbreviated from Quick Response code) is a type of matrix barcode
> (or two-dimensional code) designed to be read by smartphones. The code
> consists of black modules arranged in a square pattern on a white background.
> The information encoded may be text, a URL, or other data.

First of all, in order to build a QR code you will need [rQRCode][3] gem:

``` bash
gem install rqrcode
```

You can see example of usage right on rQRCode's homepage, so there's no need for
copy-pasting demos. So we'll begin with more complex examples... But before we
start let's get some basic ideas about QR code:

* It's a matrix of true/false dots
* It has equal width and height


### QR code with HTML5 canvas

I know that there is a native JavaScript version of QR code generator (in fact
rQRCode is a port of that library) but it seems like it's outdated. To be honest
this example was posted here just for fun - I always wanted to play with canvas
element but didn't had anything interesting to do. Now I found at least something
more or less interesting ;))

Let's assume, that we have a canvas element with id `qr` and text content that
was produced by rQRCode, something like this:

``` ruby
puts RQRCode::QRCode.new('http://www.example.com/').to_s(:true => '#')
```

Now, to convert that string, we can use this simple JavaScript, that will
replace `#` chars with black dots and ` ` (spaces) with white dots:

``` javascript
var scale   = 4,                              // each dot's size in pixels
    dark    = '#',                            // char representing "dark" dot
    qr      = document.getElementById('qr'),  // canvas element
    data    = qr.textContent,                 // QR code as a string
    context = qr.getContext('2d');            // context used to draw dots

// jQuery alike array iterator
var each = function each(arr, fn) {
  var i, l;
  for (i = 0, l = arr.length; i < l; i++) {
    fn(i, arr[i]);
  }
};

// set canvas dimensions. amount of line breaks + 1 dot (last line has no NL)
qr.width = qr.height = scale * data.match(/\n/g).length + scale;

// for each row
each(data.split(/\n/), function (y, row) {
  y *= scale;

  // for each col
  each(row.match(/./g), function (x, col) {
    x *= scale;

    context.fillStyle = (dark === col) ? '#000' : '#fff';
    context.fillRect(x, y, x + scale, y + scale);
  });
});
```

That's so simple! In fact I was even disappointed - it was not as fun as I was
expecting it to be ;)) But at least it works. You can try it easily, by
downloading _sample-1.html_ from _support bits_ of this article (see sources of
my [blog on GitHub][4]).


### Let's bring some Magick...

To be honest preparing QR code with Rmagick is also not a big issue. The biggest
issue is to install [RMagick][5] gem ;)) But installation of rmagick is out of
scope of this post. For me it was as simple with Ruby 1.9.2 as:

``` bash
gem install rmagick
```

Now, let's get to the most interesting part... To grab _dots_ of our QR code we
will use `modules` attribute of `rQRCode` instance and it's method `dark?`.

First of all in order to save some time and lots of nerves, we need to
understand that `modules` is a matrix represented by 2-dimension array where
first dimension is a row, second - column, and `dark?(row, col)` returns
whenever given column in a row should be dark or not.

``` ruby
qr.modules[1][2] // -> second row, third column
qr.dark?(1, 2)   // -> whenever second row, third column should be dark or not
```

After you got the idea about _internal secrets_, you can easily create your own
QR code image generator, like this:

``` ruby
require 'rqrcode'
require 'RMagick'

# usage: ruby sample-2.rb "http://www.example.com" /tmp/demo.png

INPUT   = ARGV[0]
OUTPUT  = ARGV[1]
SCALE   = 4


# prepare qr and img objects
qr    = RQRCode::QRCode.new(INPUT)
size  = qr.modules.count * SCALE
img   = Magick::Image.new(size, size)


# draw matrix
qr.modules.each_index do |r|
  row = r * SCALE

  qr.modules.each_index do |c|
    col = c * SCALE
    dot = Magick::Draw.new

    dot.fill(qr.dark?(r, c) ? 'black' : 'white')
    dot.rectangle(col, row, col + SCALE, row + SCALE)
    dot.draw(img)
  end
end


# produce image
img.write OUTPUT
```


### Going wild

Although examples above are clean enough, real life usage is much more
interesting than an abstract horse in surrealistic vacuum. ;)) That's why I have
added QR Code into the bottom of each page (visible on "printer-friendly"
version of styles). Explanation of how did I made this is big enough to become
separate article. So, you can either wait for my new post or take a look at
sources (see revision [cf2c8c71c5440cebfe1b601f4449ae6a711b9002][8]) of my blog
for interesting files:

* config.ru
* templates/layout.rhtml
* public/js/application.js


### Legal Note

"QR Code" is registered trademark of [DENSO WAVE][6] INCORPORATED.

This registered trademark applies only for the word "QR Code", and not for the
QR Code pattern (image). See [QR Code Patent FAQ][7] for more info.


[1]: http://en.wikipedia.org/wiki/QR_code
[2]: http://www.wikipedia.org/
[3]: http://whomwah.github.com/rqrcode/
[4]: https://github.com/ixti/blog
[5]: https://github.com/rmagick/rmagick
[6]: http://www.denso-wave.com/en/adcd/
[7]: http://www.denso-wave.com/qrcode/faqpatent-e.html
[8]: https://github.com/ixti/blog/tree/cf2c8c71c5440cebfe1b601f4449ae6a711b9002
