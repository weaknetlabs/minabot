Manual
--------

strings:
--------
./strings/*.txt

strings files that will be called with some sort of randomness for responding
in conversation. Files are named accoring to the category in which they are.

neg_adj, for instance is negative adjectives.

variable can be put into the strings, but must coorespond with the array name
in which you want them to be pulled from. Their place holder must begin with
a "!-"

!-neg_adj, for instance will randomly set a negative adjective from the
neg_adj file into the variable place holderbefore the bot says the sentence.


./dev/webtemplate.pl:
-----------------------
This file is a place to work on parsing HTML output.


YouTube-DL:
------------
This bot uses youtube-dl from:
http://rg3.github.io/youtube-dl/
and saves them to a directory specified in config.txt
This requires Python.
