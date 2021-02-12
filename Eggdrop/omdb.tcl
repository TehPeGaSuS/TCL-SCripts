##########
# OMdB Script
##########
# Retrieves info about movies from the OMDB database
##########
# Create your own API key here: http://www.omdbapi.com/apikey.aspx
# The free API key gives you access to 1,000 daily API calls
##########

##########
# THANKS
##########
# SergioR for the help in the formatQuery stuff and for
# helping me find out why I wasn't getting any output at the begin
##########
# Operator873 for the idea of using lsearch to search for the URL in the
# text sent to the channel
##########

##########
# CHANGELOG
##########
# v1
# - Initial script
##########
# v2 
# - Added automatic fetching information about a movie, based on the title from IMDb URLs
#   when they are pasted on a channel (works for normal and action messages)
##########
# v3
# - Added channel flags to enable/disable the script on a per channel basis
# - Added user flags to limit those that can enable/disable the script
##########
# v3a
# - Fixed the script triggering in any action message even if there was
#   no URL in text provided by the user (found by juanonymous)
##########

##########
# Configuration
##########

##########
# API key
##########
set APIkey "---GET YOUR OWN---"

##########
# Trigger used to search for information about a movie in the OMDb database
##########
set omdbtrigger "!"

##########
# User flags need to activate the script (defaults to m|o)
# Specify the global and/or channel flag here
##########
set omdbflags "m|o"

##########
# End of configuration
##########
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
##########

##########
# Channel flag to use the search command (!omdb <search>)
##########
setudef flag omdb

##########
# Channel flag for automatic fetching of information when a URL is pasted
##########
setudef flag omdbauto

##########
# The following packages are required to this script to work
##########
# Usually they are provided by the tcllib package on Ubuntu/Debain based distros
# For other distros check your distro documentation
# To install it on Debian/Ubuntu, as root type de following: apt-get install tcllib
# and recompile your bot
##########
package require http
package require json

##########
# Binds
##########
bind pub - ${omdbtrigger}omdbenable omdbenable:pub
bind pub - ${omdbtrigger}omdb omdb:pub
bind pubm - "*imdb.com/title/*" omdb:fetch
bind ctcp - ACTION omdb:fetch:me


##########
# End of binds
##########


##########
# Procs
##########
proc omdbt {} {
	global omdbtrigger
	return $omdbtrigger
}

proc omdbenable:pub {nick uhost hand chan text} {
	global omdbflags
	
	set command [lindex [split $text] 0]
	set autopt [lindex [split $text] 1]
	
	if {![matchattr [nick2hand $nick] $omdbflags $chan]} {
		putserv "PRIVMSG $chan :ERROR! $nick, you don't have access to this command"
		return 0
	}
	
	if {[matchstr "" $command]} {
		putserv "PRIVMSG $chan :ERROR! Syntax: [omdbt]omdbenable \[on|off|auto <on|off>"
		return 0
	} elseif {[matchstr "on" $command]} {
		if {![channel get $chan omdb]} {
			channel set $chan +omdb
			putserv "PRIVMSG $chan :OMDb enabled successfully on $chan"
			return 0
		} else {
			putserv "PRIVMSG $chan :OMDb already enabled on ${chan}!"
			return 0
		}
	} elseif {[matchstr "off" $command]} {
		if {![channel get $chan omdb]} {
			putserv "PRIVMSG $chan :ERROR! OMDb is already disabled on $chan"
			return 0
		} else {
			channel set $chan -omdb
			putserv "PRIVMSG $chan :OMDb disabled successfully on $chan"
			return 0
		}
	} elseif {[matchstr "auto" $command]} {
		if {[matchstr "on" $autopt]} {
			if {[channel get $chan omdbauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto OMDb is already enabled on $chan"
				return 0
			} else {
				channel set $chan +omdbauto
				putserv "PRIVMSG $chan :Auto OMDb enabled on $chan"
				return 0
			}
		} elseif {[matchstr "off" $autopt]} {
			if {![channel get $chan omdbauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto OMDb is already disabled on $chan"
				return 0
			} else {
				channel set $chan -omdbauto
				putserv "PRIVMSG $chan :Auto OMDb enabled successfully on $chan"
				return 0
			}
		}
	}
}
	
proc omdb:pub {nick uhost hand chan text} {
	global APIkey omdbtrigger
	
	if {![channel get $chan omdb]} {
		putserv "PRIVMSG $chan :ERROR! OMDb not enabled on this channel. To enable it type: [omdbt]omdbenable \[on|off|auto <on|off>\]"
		return 0
	}
	
	set data [http::data [http::geturl "http://www.omdbapi.com/?[http::formatQuery apikey $APIkey t $text]" -timeout 10000]]
	::http::cleanup $data
	
	set datadict [::json::json2dict $data]
	
	set Response [dict get $datadict "Response"]
	
	if {$Response eq "False"} {
		set Error [dict get $datadict "Error"]
		putserv "PRIVMSG $chan :$Error"
		return 0
	}
	
	set Title [dict get $datadict "Title"]
	set Released  [dict get $datadict "Released"]
	set Runtime [dict get $datadict "Runtime"]
	set imdbRating [dict get $datadict "imdbRating"]
	set Plot [dict get $datadict "Plot"]
	set imdbID [dict get $datadict "imdbID"]
	
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Released:\002 $Released | \002Duration:\002 $Runtime | \002Rating:\002 $imdbRating of 10 | \002IMDb:\002 https://www.imdb.com/title/$imdbID"
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Plot:\002 $Plot"
	
	return 0
}

proc omdb:fetch:me {nick uhost hand chan keyword text} {
	if {![channel get $chan omdbauto]} {
		return 0
	}
	
	omdb:fetch $nick $uhost $hand $chan $text
}

proc omdb:fetch {nick uhost hand chan text} {
	global APIkey
	
	if {![channel get $chan omdbauto]} {
		return 0
	}
	
	if {![matchstr "*imdb.com/title/*" $text]} {
		return 0
	}
	
	# Lets grab the URL from the input provided by the user
	set url [lsearch -inline $text *imdb.com/title/*]
	
	# Now that we get the URL, lets grab the ID
	set movieID [lindex [split $url "/"] end]
	
	# NOTE: IMDb ID's aren't supposed to be longer than 9 chars, so lets lock it to only 9 chars
	set IMDbID [string range "$movieID" 0 8]
	
	# We have the ID, locked down to 9 chars, as OMDb expects. But this isn't fail proof!!!
	# If the user "tampers" the title, you'll waste on API call for nothing!
	# Nonethelss, let's proceed, because we have access to 1,000 daily API calls
			
	set data [http::data [http::geturl "http://www.omdbapi.com/?[http::formatQuery apikey $APIkey i $IMDbID]" -timeout 10000]]
	::http::cleanup $data
			
	set datadict [::json::json2dict $data]
	set Response [dict get $datadict "Response"]
	if {$Response eq "False"} {
		set Error [dict get $datadict "Error"]
		putserv "PRIVMSG $chan :$Error"
		return 0
	}
			
	set Title [dict get $datadict "Title"]
	set Released  [dict get $datadict "Released"]
	set Runtime [dict get $datadict "Runtime"]
	set imdbRating [dict get $datadict "imdbRating"]
	set Plot [dict get $datadict "Plot"]
	set imdbID [dict get $datadict "imdbID"]
	
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Released:\002 $Released | \002Duration:\002 $Runtime | \002Rating:\002 $imdbRating of 10 | \002IMDb:\002 https://www.imdb.com/title/$imdbID"
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Plot:\002 $Plot"
		
	return 0
}

putlog "OMDB v3a Loaded @ 24/06/2020 by PeGaSuS"
