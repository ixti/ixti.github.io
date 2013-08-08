---
layout:    post
category:  development
tags:      [ snippet, mongodb, index, javascript ]
title:     Get MongoDB existing indexes
---

When your application on an early development stage, your indexes are changing
very fast. And most of the time you only add more and more indexes, until you
come to the point that either MongoDB fails auto-guessing a proper index to use
or indexes are taking too much RAM. This is a simple snippet that allows get a
list of existing indexes (except built-in) of all collections in your MongoDB...

``` javascript
db.getCollectionNames().forEach(function(coll) {
  db[coll].getIndexes().forEach(function(index) {
    if ("_id_" !== index.name) {
      print("db." + coll + ".ensureIndex(" + tojson(index.key) + ")");
    }
  });
});
```

You can either run this script inside mongo shell, or save this into
`show-indexes.js` file and execute it as follows:

```
$ cat show-indexes.js | mongo --quiet my-database
```
