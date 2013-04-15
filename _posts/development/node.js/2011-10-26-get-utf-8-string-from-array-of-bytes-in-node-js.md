---
layout:   post
category: development/node.js
tags:     utf8 decode string javascript
title:    Get UTF-8 string from array of bytes in Node.JS
---

While I was working on [js-yaml][1] - JavaScript port of PyYAML (by the time of
writing this post, js-yaml is still in WIP stage), I found that I need something
to convert stream of bytes into a string. So this is a quick and simple example
of how to get an UTF8 string from the stream of bytes.

Lets start with problem definition: "We need to get string from its
representation in bytes". In python it would be something akin
to this (assuming `codes` is a list of integers):

``` python
bytes(codes).decode('utf-8')
```

Now lets encode and then decode a Russian word, that describes my feeling about
using JavaScript on the server: `какашка`. We can get array of UTF8 bytes
representation of a string with following snippet:

``` javascript
function getBytes(str) {
  var bytes = [], char;
  str = encodeURI(str);

  while (str.length) {
    char = str.slice(0, 1);
    str = str.slice(1);

    if ('%' !== char) {
      bytes.push(char.charCodeAt(0));
    } else {
      char = str.slice(0, 2);
      str = str.slice(2);

      bytes.push(parseInt(char, 16));
    }
  }

  return bytes;
};
```

The function above returns an array of integers, so for example, it will return
`[90]` for `'Z'`, or `[208, 175]` for `'Я'` or `[90, 208, 175]` for `'ZЯ'`. Now
lets get bytes array for our "magic word"...

``` javascript
var bytes = getBytes('какашка');
// -> [ 208, 186, 208, 176, 208, 186, 208, 176, 209, 136, 208, 186, 208, 176 ]
```

And now! Ladies and Gentlemen! _\*drum roll\*_ Here is our snippet to get
string representation back:

``` javascript
var buff = new Buffer(bytes);
console.log(buff.toString('utf8'));
// -> какашка
```

[1]: https://github.com/nodeca/js-yaml
