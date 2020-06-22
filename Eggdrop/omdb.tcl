##########
# OMdB Script
##########
# Retrieves info about movies from the OMDB database
##########
# Create your own API key here: http://www.omdbapi.com
##########
# Thanks to SergioR for the help in the formatQuery stuff and for
# helping me find out why I wasn't getting any output at the begin
##########

##########
# CHANGELOG
##########
# v1 - Initial script [21/06/2020]
##########
# v2 - Added automatic fetching information about a movie, based on the title from IMDb URLs
# when they are pasted on a channel (works for normal and action messages) [22/06/2020]
##########


##########
# Configuration
##########
set omdbtrigger "!"
set APIkey "--GET YOUR OWN--"

##########
# End of configuration
##########
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
##########

##########
# The following packages are required to this script to work
##########
package require http
package require json

##########
# Binds
##########
bind pub - ${omdbtrigger}omdb imdb:pub
bind pubm - "*http*imdb*title*" imdb:fetch
bind ctcp - ACTION imdb:fetch:me


##########
# End of binds
##########


##########
# Procs
##########
proc imdb:pub {nick uhost hand chan text} {
	global APIkey
	
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
	set imdbID [dict get $datadict "imdbID"]
	
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Released:\002 $Released | \002Duration:\002 $Runtime | \002Rating:\002 $imdbRating of 10 | \002IMDb:\002 https://www.imdb.com/title/$imdbID"
	
	return 0
}

proc imdb:fetch:me {nick uhost hand chan keyword text} {
imdb:fetch $nick $uhost $hand $chan $text
}

proc imdb:fetch {nick uhost hand chan text} {
	global APIkey
	
	foreach word [split $text] {
		if {[matchstr "*http*imdb*title*" $word]} {
			set movie [lindex [split $word "/"] end]
			putlog "$movie"
		}
	}
			
	set data [http::data [http::geturl "http://www.omdbapi.com/?[http::formatQuery apikey $APIkey i $movie]" -timeout 10000]]
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
	set Plot [dict get $datadict "Plot"]
	set imdbRating [dict get $datadict "imdbRating"]
		
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Released:\002 $Released | \002Duration:\002 $Runtime | \002Plot:\002 $Plot| \002Rating:\002 $imdbRating of 10"
		
	return 0
}

putlog "OMDB v2 Loaded @ 22/06/2020"
