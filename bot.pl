#!/usr/bin/perl
# (c) GNU weaknetlabs@gmail.com
#
# Artificial Intelligence Bot
#
use warnings;
use strict;
use POE;
use POE::Component::IRC;
use LWP::UserAgent;

sub config($);		# read configuration
sub say($$); 		# what to say,to whom
sub pause();		# for some realism
sub linecount($);	# how many lines in strings file
sub randline($);	# return a random line from strings file
sub question($$);	# question,who asked
sub flip();		# flip a coin for realism
sub ask($$); 		# bot is asking question, ask(ques,boolean)
sub ask_reponse($);	# process response to bots question
sub xbla();		# xbox live arcade new releases
sub ytdl($);		# YouTube DL: because, fuck you google.
sub httpget($$);	# http requests in one place
sub help();		# ?help list commands

my $nick = config('nick');
my $ircname  = config('ircname');
my $server   = config('server');
my $channel = config('channel');
my $port = config('port');
my $username = config('username');

my ($irc) = POE::Component::IRC->spawn();

### Some globals  for the bot's backstory and conversation ###
my $act_present; # what is the bot doing right now?
my $act_past; 	 # what did the bot do today?
my $act_future;	 # what is the bot doing later?
my $with_who; 	 # who was/is the bot with?
my $food;	 # what did the bot eat today, or will tonight?
my $band;	 # what is the bot listening to?
my $ques_ask = 0;# question boolean on/off
my $ques_res = 0;# type of response the bot wants 1=pos,0=neg
my $cur_topic;	 # current topic we are on
my $topic_mod="";# strings that have (thing) in them
my $xbla_timer;  # same.
my @xbla;	 # for simple http traffic throttle/cache
my $ytdlpath = config("ytdlpath");

POE::Session->create(
	inline_states => {
		_start     => \&bot_start,
		irc_001    => \&on_connect,
		irc_public => \&on_public,
	},
);

sub on_public { # this will respond to messages from your channel
	my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
	$who =~ s/!.*//; # remove trash
	my $nick    = (split /!/, $who)[0];
	my $channel = $where->[0];
	if($topic_mod ne "" && $msg =~ m/^wh((at|ere|en|y|ich)|^how)/i){
		say($topic_mod,"");
		return;
	}
	if($ques_ask == 1){
		ask_reponse($msg);
		return;
		if(date() ne $xbla_timer){
			httpget("xbla","");
			foreach(@xbla){
				say($_,"");
			}
		}
	### COMMANDS ###
	}elsif($msg =~ m/^\?ipad/i){
		my $type = $msg;
		$type =~ s/.* ([a-z0-9@_-]+)$/$1/;
		httpget("ipad",$type);
	}elsif($msg =~ m/^\?help/i){
		help();
	}elsif($msg =~ m/\?360(news)?/i){
		httpget("360","");
	}elsif($msg =~ /^\?xbla/i){
		httpget("xbla","");
	}elsif($msg =~ m/^\?proxylist/i){
		httpget("proxy","");
	}elsif($msg =~ m/^\?anon(news)?/i){
		httpget("anon","");
	}elsif($msg =~ m/\?ytdl/i){
		$msg =~ s/.*http/http/;
		ytdl($msg);
	}elsif($msg =~ m/^\?twitter/i){
		my $tw = $msg;
		$tw =~ s/.* ([a-z0-9@_-]+)$/$1/;
		if($tw eq ""){
			say("please provide a twitter \@name","");
			return;
		}
		httpget("tweet",$tw);
	}elsif($msg =~ m/^\?ass(embler)?/i){
		httpget("assembler","")
	### END COMMANDS ###

	}elsif($msg =~ m/^((is|are|was|were|why|how|what|when|do|where)|[ur] )/i){
		question($msg,$who);
		return;
	}
	if($msg =~ m/((^stop)|(pl(ease|z) )?don(')?t .*)/i){
		say("sorry.","");
	}elsif($msg =~ m/\$[0-9]/i){
		say("more money plz.","");
	}elsif($msg =~ m/(^mina|h[ea](llo|y+(a)?|i) mina)/i){  ## initiate conversation ##
		say(randline('greetings'),$who);
		$act_present = 	randline('actions_present');
		$act_past = 	randline('actions_past');
		$with_who = (flip() == 0)?randline('people'):randline('people')." and ".randline('people'); #1337
		$band = 	randline('bands');
		$food = 	randline('foods');
		$act_future = 	randline('actions_future');
		return;
	}elsif($msg =~ m/^h(i|ello|e[yj])/i){
		say(randline('greetings'),"");
	}elsif($msg =~ m/^let'?s/i){
		say("k.","");
	}elsif($msg =~ m/^thank(s| you)/i){
		say("np, !-user :)",$who);
	}elsif($msg eq "lol"){
		say(lol(),"");
	}elsif($msg =~ m/l+o+v+e+/i){
		say(randline('pos_responses'),"");



	### random responses below ###
	}elsif($msg =~ m/(^l[oue]l|l[oue]l$)/i){
		say(lol(),"");
	}elsif($msg =~ m/[:;8B][DP})\]\/p*3]/){
		say(face(),"");
	}else{
		# DEBUG
		#say($msg,"");
	}
	return;
}

sub face(){ # random semi-happy face
	my $face;
	my @eye = (':',';','B','8','%','x','X','=');
	my @mouth = ('D','X','x','3','E',']','o','0','V',')','p','P');
	my $nose = int(rand(2));
	$face = $eye[int(rand($#eye))];
	$face .= '-' if($nose);
	$face .= $mouth[int(rand($#mouth))];
	return $face;
}

sub ask($$){ # the bot is asking a question
	say($_[0],"");
	$ques_ask = 1;
	$ques_res = $_[1];
	return;
}

sub ask_reponse($){
	if($_[0] =~ m/(no|naw|nope|nein|nay)/i){
		# we received a negative response
		if($ques_res == 0){
			say(randline('pos_responses'),"");
		}else{
			say(randline('neg_responses'),"");
		}
		$ques_ask = 0; # reset stuff
		$ques_res = 0;
	}elsif($_[0] =~ m/(yes|yeah|yup|yep|yee|ye|jyeah|yesh|yush)/i){
		# we received a positive response
		if($ques_res == 1){
			say(randline('pos_responses'),"");
		}else{
			say(randline('neg_responses'),"");
		}
		$ques_ask = 0; # reset stuff
		$ques_res = 0;
	}elsif($_[0] =~ m/don(')?t.*know/i){
		# they don't know
		say(randline('rand_responses'),'');
	}

	## let's give the bot to ask some questions
	return;
}

sub lol(){ # dynamic lulz!
	my $lol;
	for(my $i=0;$i<=int(rand(6+3));$i++){
		$lol = (int(rand(2)) == 1)?$lol .= "l":$lol .= "o"; #1337
	}
	return $lol.="ol";
}

sub question($$){
	my $lol = 1 if($_[0] =~ m/(^lol|lol$)/i);
	if($_[0] =~ m/(who|what).*(listening).*to/i){
		say($band,"");
		$cur_topic = "music";
	}elsif($_[0] =~ m/(do |did )?you (ever )?(listen|hear|jam)( of | to )?(the )?([a-z0-9_*#@\/=+& -]+)\?/i){
		my $band = $6;
		my @bands = `cat strings/bands.txt`;
		if(grep(/$band/i,@bands)){
			say(randline('pos_responses'),"");
		}else{
			say(randline('neg_responses'),"");
		}
	}elsif($_[0] =~ m/what.*(do(\?)?|up doing).*(today|earlier)/i){
		say($act_past,""); # what did the bot do prior to irc
	}elsif($_[0] =~ m/(any|wha)(t|chu).*(plans|doing|cool|going on).*(later|tonight|this (evening|afternoon|morning))/){
		say($act_future,""); # what is the bot doing later?
	}elsif($_[0] =~ m/(wha)(t|chu).*(are)?.*(up to|doing|going on|up)/i){ # whats are we doing
		say($act_present,"");
	}elsif($_[0] =~ m/(who.*with|with.*who)/i){ # who are/were we with
		say($with_who,"");
	}elsif($_[0] =~ m/what.*(game)?.*( are you|cha) playing/i){ # video games currently playing
		$cur_topic = "vgames";
		say(randline('vgames'),"");
		ask("you play video games?",1);
	}elsif($_[0] =~ m/(do )?(yo)?u play ([a-z0-9_ ]+)\?/i){
		my @vgames = `cat strings/vgames.txt`;
		if(grep(/$3/i,@vgames)){
			say(randline('pos_responses'),'');
		}else{
			say(randline('neg_responses'),'');
		}
	}elsif($_[0] =~ m/w(ill|oul(d)?|an)(na|t to)?( (yo)?u)? ([a-z0-9_]+)/i){ # would or wouldnt you do ...
		my @would = `cat strings/would.txt`;
		my @wouldnt = `cat strings/wouldnt.txt`;
		if(grep(/$6/i,@would)){
			say(randline('pos_responses'),"");
		}elsif(grep(/$6/i,@wouldnt)){
			say(randline('neg_responses'),"");
		}else{
			say("probably not.","");
		}
	}else{
		say(randline('dontknow'),"");
		# nothing yet
	}
	say(lol(),'') if ($lol); # lol?
	return;
}

sub flip(){ # heads or tails
	return int(rand(2)); # rand is between 0 and passed int, which is 2
		# thisd would yield either 0, or 1.
}

sub say($$){ ### talk in the channel ### 
	$poe_kernel->delay(5);
	# tokyo (chinese/japanese buffet)
	# $irc->yield(privmsg => $channel,"\$_[0]: ".$_[0]); # DEBUG
	my $resp = $_[0]; 		# final response
	if($_[0] =~ m/\(.*\)$/){     	# we have a modifier in our string
		my $what = $_[0];
		$what =~ s/.*\((.*)\)$/$1/; # Perl needs to knock it off with the empty sub bug ffs
		if($what =~ m/^!-(.*)/){
			$topic_mod = randline($1);    # turn on boolean for modifier
		}else{
			$topic_mod = $what; # no randomness plz
		}
		$resp =~ s/\(.*\)$//; # remove modifier from string
	}else{
		$topic_mod = ""; # reset it!
	}
	## modifiers here roll some d20s.
	$resp =~ s/!-user/$_[1]/; # put in who asked it first
	if($resp =~ m/!-([a-z_]+)/i){ # my own variable syntax == !-varname
		my $rl = randline($1);# which corresponds to a filename in 
		$resp =~ s/!-$1/$rl/i;  # ./strings/varname.txt
	}
	#pause();
	$irc->yield(privmsg => $channel, $resp);
	return;
}
# these file methods are cheaper than those used by
# all of the stuff used with file functions.
sub randline($){ # get the random line from file randline(line-no,file);
	my $file = "./strings/".$_[0].".txt";
	my $lc = `wc -l $file|awk '{print \$1}'`;
	$lc = int(rand($lc));
	$lc = 1 if($lc < 1); # this can't be zero for sed to work
	my $line = `sed '$lc q;d' $file`;
	chomp $line;
	return $line;
}

sub pause(){ # for a little realism!
	sleep int(rand(5)+2);
	return;
}
sub date(){
	my @date = localtime;
	return $date[3].$date[4].$date[5];
}
sub gogl($){
        my $goglurl = "https://www.googleapis.com/urlshortener/v1/url";
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $req = HTTP::Request->new(POST => $goglurl);
        $req->content_type('application/json');
        $req->content("{\"longUrl\": \"$_[0]\"}");
        my $res = $ua->request($req);
        my @data = split /\n/, $res->content;
        foreach my $line (@data) {
                chomp($line);
                if ($line =~ /\"id\": \"(.*)\"/){
                        return $1;
                }
        }
}
sub ytdl($){
	my $vidid = $_[0];
	$vidid =~ s/.*\?v=//;
	if($_[0] !~ m/^http:..(www.)?youtube/){
		say("c'mon, give me a *real* YouTube URL. ","");
		say("derp","");
		return;
	}
	say(randline('yt'),"");
	system("./youtube-dl --id $_[0] 1>/dev/null");

	while(`ls -l $vidid.mp4|wc -l|awk '{print \$1}'` == 0){
	        sleep 1;
	}
	system("mv $vidid.mp4 $ytdlpath$vidid.mp4");
	say("here ya go","");
	say("$ytdlpath$vidid.mp4\n","");
	return;
}
sub httpget($$){ # $_[0] what to get, $_[1] extra param
	# I made this is to reduce repeated code
	# Once you figure out how to parse the html/rss/etc, just make an elsif()
	# and simply call $ua-get() on the URL
	my $ua = LWP::UserAgent->new(); # generic, http get setup
	$ua->agent('Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36');
	my $i = 0; # this token is for simple results throttling
	if($_[0] eq "proxy"){ 	  ### ProxyListChecker
		my $res = $ua->get('http://proxylistchecker.org/proxylists.php?t=anonymous');
		my @lines = split(/oxy'>/,$res->content);
		foreach(@lines){
		        last if($i==10);
		        my $line = $_;
		        if($line =~ m/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/){
		                $line =~ s/<.*//;
		                say($line,"");
		        }
		        $i++;
		}
	}elsif($_[0] eq "anon"){  ### AnonNews
		my $res = $ua->get('http://anonnews.org/press/list/date/desc/');
		my @lines = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
		foreach(@lines){
		        last if($i==11);
		        my $line = $_;
		        if($line =~ m/class="name"/i){
		                my $url = $line;
		                $url =~ s/.*"\///;
		                $url =~ s/".*//;
		                $url = "http://anonnews.org/".$url;
		                my $title = $line;
		                $title =~ s/.*name">//i;
		                $title =~ s/<.*//;
		                say($title." - ".$url,"");
		                $i++;
		        }
		}
	}elsif($_[0] eq "tweet"){ ### Twitter
		my $res = $ua->get('https://twitter.com/'.$_[1]);
		my @lines = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
		foreach(@lines){ 
			if($_ =~ m/Sorry, that page do/i){ # user doesn't exist
				say("That username doesn't exist.","");
				return;
			}
		        if($_ =~ m/tweet-text">/i && $_ !~ m/Retweeted by /i){ # don't need these
				last if($i==6);
		                my $line = $_; # let's parse it out
		                $line =~ s/&#39;/'/g;
		                $line =~ s/(&(nbsp|quot);|â¦)//g;
		                $line =~ s/<[ a-z0-9%@&:;"\/\\=?._-]+>//ig;
				$line =~ s/^\s+//; # annoying spaces
		                say($line,""); # spam the tweet
				$i++;
		        }
		}
	}elsif($_[0] eq "xbla"){ ### XBOX Live Arcade Releases
	        my $res = $ua->get('http://marketplace.xbox.com/en-us/Games/xboxarcadegames?SortBy=ReleaseDate');
	        my @array = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
	        my $rating = 0;
	        my $rate = 0;
	        my $count = 0;
	        my $line = "";
	        my $url;
	        sub gogl($);
	        foreach(@array){
	                if($_ =~ m/<h2>/i){
	                        $url = $_;
	                        $url =~ s/.*f="//;
	                        $url =~ s/".*//;
	                        $url = gogl("http://marketplace.xbox.com".$url);
	                        my $title = $_;
	                        $title =~ s/.*">//i;
	                        $title =~ s/<.*//i;
	                        $line = $title . " ";
	                }
	                if($_ =~ m/star star([0-5])/i){
	                        $rating+=$1;
	                        $rate++;
	                        if($rate == 5){
	                                $line .= "(".$rating. "/20) ";
	                                $rate = 0;
	                                $rating = 0;
	                        }
	                }
	                if($_ =~ m/ProductMeta/i){
	                        my $date = $_;
	                        $date =~ s/.*">//i;
	                        $date =~ s/<\/.*//i;
	                        $line .= $date . " -- " . $url;
	                        say($line,""); # say it don't spray it!
	                        push(@xbla,$line);
	                        $xbla_timer = date();
	                        $count++;
	                }
	                if($count == 7){
	                        last;
	                }
	        }
	        say("more info: http://goo.gl/LvKk8w","");
	}elsif($_[0] eq "assembler"){ ### Assembler Weblog
		my $res = $ua->get('http://www.assemblergames.com/forums/blog.php');
		my @lines = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
		my $a = 0;
		foreach(@lines){
		        last if($a==5);
		        my $line = $_;
		        if($line =~ m/class="blogtitle"/i){
		                my $url = $line;
		                $url =~ s/.*ref="//;
		                $url =~ s/".*//;
		                $url =~ s/&amp.*//;
		                $url = "http://www.assemblergames.com/forums/".$url;
		                my $title = $line;
		                $title =~ s/.*title">//i;
		                $title =~ s/<.*//;
		                say($title." - ".$url,"");
		                $a++;
		        }
		}
	}elsif($_[0] eq "360"){
		my $res = $ua->get('http://www.xbox360news.com/');
		my @lines = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
		my $a = 0;
		foreach(@lines){
			last if($a==7);
			my $line = $_;
			if($line =~ m/NL_TitleLink/i){
				my $url = $line;
				$url =~ s/.*href='(.*)' .*/$1/;
				$url = gogl($url);
				my $title = $line;
				$title =~ s/.*NL_TitleLink'>(.*)<\/.*/$1/i;
				say($title." - ".$url,"");
				$a++;
        		}
		}
	}elsif($_[0] eq "ipad"){
		my $res;
		if($_[1]){
			if($_[1] eq "popular"){
				$res = $ua->get('http://appshopper.com/feed/?mode=featured&filter=price&type=free&category=games&device=ipad&platform=ios');
			}else{
				$res = $ua->get('http://appshopper.com/feed/?mode=all&filter=price&type=free&category=games&device=ipad&platform=ios');
			}
		}
		my @lines = split(/\015?\012/,$res->content); # splits up HTML from HTTP Returned Hex
		my $a = 0;
		foreach(@lines){
			last if($a==10);
			my $line = $_;	
			if($line =~ m/Price Drop/i){
				my $title = $line;
       	        		$title=~s/.*:(\s)?//;
       		         	$title =~ s/<.*//;
	       	         	$title =~ s/.*NL_TitleLink'>(.*)<\/.*/$1/i;
       	        		say($title,"");
        	        	$a++;
        		}
		}
	}else{
		# not yet
	}
	return;
}

sub help(){
	my @list = (
		'360 - Xbox 360 News',
		'xbla - Xbox Live Arcade New Releases',
		'proxylist - Free Proxy List',
		'anon - Your Anonymous News',
		'twitter (username) - Check Tweets',
		'ytdl - YouTube Downloader', # http://rg3.github.io/youtube-dl/
		'ipad - iOS game price drops',
		'assembler - Assembler Blog',
	);
	foreach(@list){
		say($_,"");
	}
	return;
}


### Sub routines for IRC module below ###
###   These should not need changed   ###

sub bot_start { # set up the bot's nick, sever, etc
  $irc->yield(register => "all"); # here
  my $nick = 'mina';
  $irc->yield(
    connect => {
      Nick     => $nick,
      Username => $username,
      Ircname  => $ircname,
      Server   => $server,
      Port     => $port,
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  	$irc->yield(join => $channel);
	say(randline('greetings'),"");
}
sub config($){
	open(CFG,"config.txt") || die "couldn't read configuration file";
	while(<CFG>){
		if($_ =~ m/^$_[0]/){
			my $config = $_;
			chomp $config;
			$config =~ s/.*= //;
			return $config;
		}
	}
}
$poe_kernel->run();
