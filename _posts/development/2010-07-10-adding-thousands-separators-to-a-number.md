---
layout:   post
category: development
tags:     cli perl php python regexp ruby
title:    Adding thousands separators to a number
---

Today Marco shared on his blog an idea how to [add thousands separators on
CLI][1] with help of standard printf function, and Perl, and sed, and awk.
So I want to extend his post with same thing but in PHP, Ruby and Python.
Of course you can achieve same with `printf` functions of these langauages
and setting correct locale, but it's not as interesting as one-line things.
So here we go...

### PHP

There are many ways to achieve this. But I'm going to show the most short and
clean variants :)) Let's start with regular expressions usage. First way is to
split string with regular expression into an array of chunks and then join them
with comma clue, like this:

```
$ php -r 'echo implode(&quot;,&quot;, preg_split(&quot;/(?&lt;=\d)(?=(\d{3})+$)/&quot;, $argv[1])) . &quot;\n&quot;;' 1234
```

Also, you can use `preg_replace()` function:

```
$ php -r 'echo preg_replace(&quot;/(\d{1,3})(?=(\d{3})+$)/&quot;, &quot;\\1,&quot;, $argv[1]) . &quot;\n&quot;;' 1234
```

And finally you can simply use `number_format()` function:

```
$ php -r 'echo number_format($argv[1], 0, &quot;.&quot;, &quot;,&quot;) . &quot;\n&quot;;' 1234
```


### Ruby

```
$ ruby -e 'puts ARGV[0].gsub(/(\d{1,3})(?=(\d{3})+$)/, &quot;\\1,&quot;)' 1234
```


### Python

In fact I don't have lot's of practice in Python every-day usage, so if you know
better variant, feel free to share it and point me that I'm shit ;))

```
$ python -c 'import sys,re; print re.sub(r&quot;(\d{1,3})(?=(\d{3})+$)&quot;, &quot;\\1,&quot;, sys.argv[1])' 1234
```


### Perl
Basically this is alternative version of Marco's variant, that I've just posted
as a comment to his post :)) So I'm placing it here just to keep it for myself.
In Perl you can achieve this with only assertions (like with `preg_split()` of
PHP):

```
$ perl -pe 's/(?&lt;=\d)(?=(\d{3})+$)/,/g' &lt;&lt;&lt; 1234
```

Or with only one asserion:

```
$ perl -pe 's/(\d{1,3})(?=(\d{3})+$)/\1,/g' &lt;&lt;&lt; 1234
```


[1]: http://mydebian.blogdns.org/?p=777
