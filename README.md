<img src="https://weaknetlabs.com/images/wilhelminalogo-git.png"/>

# Manual
Wilhemina is an IRC chat bot, powered by Regular Expessions.

# Strings:
All strings are located and can be easily edited in the ./string directory. Strings files that will be called with some sort of randomness for responding in conversation. Files are named accoring to the category in which they are.

"neg_adj", for instance is negative adjectives.

Variables can be put into the strings, but must coorespond with the file name in which you want them to be pulled from. Their place holder must begin with a "!-"

"!-neg_adj", for instance will randomly set a negative adjective from the neg_adj file into the variable place holderbefore the bot says the sentence.

<b>Output Examples:</b> http://pastebin.com/pzbSh0nQ, http://pastebin.com/qssrHaph<br />
<b>Awesome Regexp example:</b> http://pastebin.com/RSePU7yE

# YouTube-DL
This bot uses youtube-dl from:
http://rg3.github.io/youtube-dl/
and saves them to a directory specified in config.txt
This requires Python.
