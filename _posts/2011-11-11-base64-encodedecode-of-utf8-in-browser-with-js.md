---
layout:   post
category: development/javascript
tags:     base64 utf8 unicode javascript snippet
title:    Base64 encode/decode of UTF8 in browser with JS
---

While working on [live demo of JS-YAML][1], our pure JavaScript port of exciting
[PyYAML][2]. I found that there's absolutely no ready solutions for encoding and
decoding Base64 in JavaScript for unicode. Tons of Base64 encoders/decoders that
will blow out your unicode string like `я обожаю ириьски` into something
absolutely useless. Tons of utf8 encoders/decoders that just do not work.
So I wrote my own...

Let's start with encoding/decoding Unicode strings. The easiest part here is
decoding:

``` javascript
function utf8Decode(bytes) {
  var chars = [], offset = 0, length = bytes.length, c, c2, c3;

  while (offset < length) {
    c = bytes[offset];
    c2 = bytes[offset + 1];
    c3 = bytes[offset + 2];

    if (128 > c) {
      chars.push(String.fromCharCode(c));
      offset += 1;
    } else if (191 < c && c < 224) {
      chars.push(String.fromCharCode(((c & 31) << 6) | (c2 & 63)));
      offset += 2;
    } else {
      chars.push(String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63)));
      offset += 3;
    }
  }

  return chars.join('');
}
```

This function is straight forward and dead simple, so we won't talk about it too
much. It receives array of unicode bytes and returns a simple string. Now, the
most interesting part is encode unicode stream into array of bytes.


I saw lots of variants and all they was not working properly. Mostly because
authors forget that `String#length` on unicode string in browser is little bit
unpredictable (otherwise  you would not read this post). So we can simply throw
away about 95% of such implementations. I even saw attempt to use `String#split`
to calculate length of the string - nice but useless try...

The most viable solution I saw was using regular expressions. The idea was good,
the implementation was shit - in fact, author was simply lack of regular
expression usage practice. Anyway, everybody  miss the most simple solution...
We have native function `encodeURI` which converts a string to be used as part
of the URI, and that string contains bytes representation of non-ASCII chars n
form of `%XX`, where `XX` is a hexadecimal code. So we can use such string to
build desired array of bytes. And here we are:

``` javascript
function utf8Encode(str) {
  var bytes = [], offset = 0, length, char;

  str = encodeURI(str);
  length = str.length;

  while (offset < length) {
    char = str[offset];
    offset += 1;

    if ('%' !== char) {
      bytes.push(char.charCodeAt(0));
    } else {
      char = str[offset] + str[offset + 1];
      bytes.push(parseInt(char, 16));
      offset += 2;
    }
  }

  return bytes;
}
```

OK. now the most easiest part - Base64 encode/decode. I would not talk too much
about it, as it's straight forward task, and in fact almost every solution I
found on the Internet was working (more or less). So I used the most easy to
read and understand one - the part of [Mozilla's XML-RPC client][3] with few
tuning I made to meet my requirements of code style mostly. Here's the result:

``` javascript
var noop = function () {},
    logger = {warn: noop, error: noop},
    padding = '=',
    chrTable = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' +
               '0123456789+/',
    binTable = [
      -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
      -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
      -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,62, -1,-1,-1,63,
      52,53,54,55, 56,57,58,59, 60,61,-1,-1, -1, 0,-1,-1,
      -1, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
      15,16,17,18, 19,20,21,22, 23,24,25,-1, -1,-1,-1,-1,
      -1,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
      41,42,43,44, 45,46,47,48, 49,50,51,-1, -1,-1,-1,-1
    ];

if (console) {
  logger.warn = console.warn || console.error || console.log || noop;
  logger.warn = console.error || console.warn || console.log || noop;
}

function encode(str) {
  var result = '',
      bytes = utf8Encode(str),
      length = bytes.length,
      i;

  // Convert every three bytes to 4 ascii characters.
  for (i = 0; i < (length - 2); i += 3) {
    result += chrTable[bytes[i] >> 2];
    result += chrTable[((bytes[i] & 0x03) << 4) + (bytes[i+1] >> 4)];
    result += chrTable[((bytes[i+1] & 0x0f) << 2) + (bytes[i+2] >> 6)];
    result += chrTable[bytes[i+2] & 0x3f];
  }

  // Convert the remaining 1 or 2 bytes, pad out to 4 characters.
  if (length%3) {
    i = length - (length%3);
    result += chrTable[bytes[i] >> 2];
    if ((length%3) === 2) {
      result += chrTable[((bytes[i] & 0x03) << 4) + (bytes[i+1] >> 4)];
      result += chrTable[(bytes[i+1] & 0x0f) << 2];
      result += padding;
    } else {
      result += chrTable[(bytes[i] & 0x03) << 4];
      result += padding + padding;
    }
  }

  return result;
}

function decode(data) {
  var value, code, idx = 0,
      bytes = [],
      leftbits = 0, // number of bits decoded, but yet to be appended
      leftdata = 0; // bits decoded, but yet to be appended

  // Convert one by one.
  for (idx = 0; idx < data.length; idx++) {
    code = data.charCodeAt(idx);
    value = binTable[code & 0x7F];

    if (-1 === value) {
      // Skip illegal characters and whitespace
      logger.warn("Illegal characters (code=" + code + ") in position " + idx);
    } else {
      // Collect data into leftdata, update bitcount
      leftdata = (leftdata << 6) | value;
      leftbits += 6;

      // If we have 8 or more bits, append 8 bits to the result
      if (leftbits >= 8) {
        leftbits -= 8;
        // Append if not padding.
        if (padding !== data.charAt(idx)) {
          bytes.push((leftdata >> leftbits) & 0xFF);
        }
        leftdata &= (1 << leftbits) - 1;
      }
    }
  }

  // If there are any bits left, the base64 string was corrupted
  if (leftbits) {
    logger.error("Corrupted base64 string");
    return null;
  }

  return utf8Decode(bytes);
}
```

These are all you need to Base64 encode/decode unicode in browser properly. Hope
this will help and save you some time. :))

You can download full solution from the _bits_ of this article below. The usage
is pretty simple. Require it, e.g. like this:

``` html
<script src="js/base64.js"></script>
```

and then use it like this:

``` javascript
var enc = base64.encode('я обожаю ириьски');
console.log(enc);
// -> '0Y8g0L7QsdC+0LbQsNGOINC40YDQuNGB0YzQutC4'
```


[1]: http://nodeca.github.com/js-yaml/
[2]: http://pyyaml.org/
[3]: http://lxr.mozilla.org/mozilla/source/extensions/xml-rpc/src/nsXmlRpcClient.js
