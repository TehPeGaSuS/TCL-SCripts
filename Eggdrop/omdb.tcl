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
	
	putserv "PRIVMSG $chan :\002Title:\002 $Title | \002Released:\002 $Released | \002Duration:\002 $Runtime | \002Rating:\002 $imdbRating | \002IMDb:\002 https://www.imdb.com/title/$imdbID"
	
	return 0
}

putlog "OMDB v1 Loaded @ 21/06/2020"
