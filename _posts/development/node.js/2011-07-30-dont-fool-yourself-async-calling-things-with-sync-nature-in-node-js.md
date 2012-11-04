---
layout:   post
category: development/node.js
tags:     callback asynchronous syscall javascript
title:    Don't fool yourself async-calling things with sync nature in Node.JS
---

I bet almost everybody knows about [Node.JS] these days. By today it's the most
popular implementation of [CommonJS]. Because of "asynchronous event-driven
model" some developers force callback based usage even with absolutely trivial
and/or synchronous things. So basically this post is just to prove some obvious
points for myself.

[Node.JS]: http://nodejs.org/
[CommonJS]: http://www.commonjs.org/

> You must unlearn what you have learned.
>
> _Master Yoda_


OK. I'm not against callback based functions. I'm not against asynchronous model
at all. But any particular thing in this world is synchronous by it's nature.
And there's no need to make simple things complicated. Don't forget to keep it
simple stupid!

Instead some of Node.JS adepts actually believes, that everything in this world
should return values via callback with `err` as first argument. Still wonders
how these people didn't forced proposing of replacing `*` operator with
"asynchronous" version, e.g.:

``` javascript
Math.multiply(2, 2, function (err, result) { /* ... */ });
```


### Checking file existence synchronously

Let's write a dummy test script that will run `path.existsSync` multiple times
and monitor how much time will it take to run it:

``` javascript
// file: exists-test-1.js
var path = require('path'),
    file = '/tmp/abc',
    count = 100000,
    title = 'Iterating ' + count + ' times';

// start timer
console.time(title);

while (count--) {
  path.existsSync(file);
}

// we're done. show us results
console.timeEnd(title);
```

Take a look what we have:

``` bash
$ for i in {1..3}; do node ./exists-test-1.js; done
Iterating 100000 times: 3589ms
Iterating 100000 times: 3596ms
Iterating 100000 times: 3590ms
```


### Checking file existence asynchronously

Now, let's replace `path.existsSync` with asynchronous `path.exists` and see
what will change:

``` javascript
// file: exists-test-2.js
var path = require('path'),
    file = '/tmp/abc',
    count = 100000,
    title = 'Iterating ' + count + ' times';

// start timer
console.time(title);

while (count--) {
  path.exists(file, function (){
    // do nothing 
  });
}

// we're done. show us results
console.timeEnd(title);
```

If you was out for a cup of coffee while running test, and if you are one of
those blind async fanboys you would probably scream _"I told you!"_

``` bash
$ for i in {1..3}; do node ./exists-test-2.js; done
Iterating 100000 times: 567ms
Iterating 100000 times: 578ms
Iterating 100000 times: 536ms
```

But if you was here while running test, you would mention that there were about
3-6 seconds of delay between test runs. And of course, if you understand it's
nature at least same primitive level as I do, you'll understand the cause.
The reasone is because, all `path.exists` were delayed and so `console.timeEnd`
was called before all `exists` were fired and handled.


### Checking file existence asynchronously (how much time will it take in fact?)

Let's modify our last test in order to show us the same time as in synchronous
version test (from entry until every single call finished):

``` javascript
// file: exists-test-3.js
var path = require('path'),
    file = '/tmp/abc',
    count = 100000,
    title = 'Iterating ' + count + ' times';

// start timer
console.time(title);

while (count--) {
  path.exists(file, function (){
    // do nothing 
  });
}

// we're done. show us results
process.on('exit', function () {
  console.timeEnd(title);
});
```

Surprise for the fanboys, but not for the most of people how are able to think
for themselves. :)) Basically results are really easy to be expected:

``` bash
$ for i in {1..3}; do node ./exists-test-3.js; done
Iterating 100000 times: 8238ms
Iterating 100000 times: 8561ms
Iterating 100000 times: 8487ms
```


### P.S.

You'll never jump above your head. Think of the processor as about a clerk doing
his paperwork. It can delay processing of some of the papers in order to accept
more incoming papers. But this won't make him work faster - will only move queue
of incoming papers from the persons awaiting to his desk, but even persons won't
get anyway, they will still be waiting.

Of course, clerk will be able to preprocess some of the papers and those who are
easier, process the same time it accepts papers, but this will delay queue
execution for more time, as first person will be forced to wait until his papers
will be processed while clerk will be serving one came after.

Yes, sometimes, probably, this behavior is what you really want. For example,
it's OK to asynchronously read/write some big amount of data, so you'll be able
to serve other clients with "smaller" needs, because in this case the one
requested "long taking" operation will not see big difference, just as you won't
mention 10 cents when you are talking about prices >100 Euros. In opposite side
you will mention extra 10 cents if the cost was 15 cents only. So pay attention
on what are you doing, don't act as a monkey, repeating someones mantras,
especially when that person see nothing further than his nose.
