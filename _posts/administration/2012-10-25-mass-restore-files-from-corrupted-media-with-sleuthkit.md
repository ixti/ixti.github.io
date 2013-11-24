---
layout:    post
category:  administration
tags:      [ hdd, files, recovery, sleuthkit, dd ]
title:     Mass-restore files from corrupted media with sleuthkit
---

Not so long ago, I mentioned that one of my external hard drives become little
bit too slow, and was not able to remove some files, and system was always
proposing me to run file system check. But I was always in hurry, until one day,
when I decided to move files to another drive. Unfortunately, by some reason, I
decided to run `fsck` before copying file on another drive. When I came in the
morning my drive was not working properly anymore...

So, I lost all my ~~porn~~ photos. It was impossible to mount it, and the syslog
was full of messages like `Buffer I/O error on device sdb`. Googling left me
with sad feeling that I will never get my data recovered. But I was wrong and
thanks to all developers of `safecopy`, `testdisk`, `sleuthkit` and `autopsy`.


##### Grabbing image of a failing drive

As you might already guessed, `dd` was useless for me. So here's where
might `safecopy` comes for the rescue :)) This brilliant application helped
me to get as much data from drive as possible without any extra work:

```
$ cd /media/storage/recover-my-broken-drive
$ safecopy --stage1 /dev/sdb sdb-data

...

$ safecopy --stage2 /dev/sdb sdb-data

...

$ safecopy --stage3 /dev/sdb sdb-data
```

Use `man safecopy` for details. :))


##### Bringing data back alive

So the next day I was able to run `testdisk` on the result image file. And it
was able to determine my filesystem. Even more, I was able to mount this image,
but it was working really buggy. So I have investigated that image with
`autopsy`. I needed all files under one particular directory and all it's
sub-directories. Unfortunately autopsy does not gives you an option to recover
"all files from that directory". But it gives you an *inode* of each file and
directory. That was what I was looking for. Now, knowing the inode of my
diretory I was able to get the list of all nested entries (files, dirs, etc):

```
$ fls -f ext2 -p -r ./sdb-data 8650754

r/r 8651063:	INCITS+ISO+IEC+14882-2003.pdf
...
```

You can read details on the output format on a [fls wiki page][fls-wik]. But in
short I needed all dirs/files that are not deleted, so the final command was:

```
$ fls -f ext2 -p -r ./sdb-data 8650754 \
  | grep -v '^..-' | grep -v '^... \*' > files.lst
```

Now I had a "clean" list of files and directories I need to restore. To restore
a directory, all we have to do is to, surprise-surprise, `mkdir` it ;)) but to
recover a file, we need to output it's content. To get contents of a file from
the image byt it's inode, I used another tool from the sleuthkit box: `icat`.
Grabbing each file manually is dead-boring task, so here's a small *BASH* script
that did all the dirty work for me:

``` bash
IMAGE=$1
LIST=$2
DEST=$3

cat $LIST | while read line; do
   filetype=`echo "$line" | awk {'print $1'}`
   filenode=`echo "$line" | awk {'print $2'}`
   filenode=${filenode%:}
   filename=`echo "$line" | cut -f 2 -d '	'`

   if [ $filetype == "r/r" ]; then
      echo "$filename"
      mkdir -p "`dirname "$DEST/$filename"`"
      icat -f ext2 -r -s $IMAGE "$filenode" > "$DEST/$filename"
   fi
done
```

And again, `man icat` for details ;))


##### That's all!

Hope this will help somebody. And I hope I will never need it by myself. ;))


[fls-wiki]: http://wiki.sleuthkit.org/index.php?title=Fls
