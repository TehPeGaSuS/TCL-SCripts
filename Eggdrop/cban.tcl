### KickBan TCL ###

# This script is highly experimental and needs eggdrop 1.9
# curently the default branch at https://github.com/eggheads/eggdrop
#
# In order for this script to work, you need to enable some features, especially:
#
# https://github.com/eggheads/eggdrop/blob/develop/eggdrop.conf#L1122
# should be set to: set cap-request "account-notify extended-join"
#
# https://github.com/eggheads/eggdrop/blob/develop/eggdrop.conf#L1379
# should be set to: set use-354 1
#
# USE AT YOUR OWN RISK! YOU HAVE BEEN WARNED!

##########
# COMMANDS
##########
# cban <nick> - bans the nick in the format *!*user@host (nick needs to be in the channel)
#
# uncban <mask|last> - Removes the specified mask or the last ban if 'last' is specified instead a mask
#
# bans - Sends a PM to the user showing the current internal ban list for the channel
#
# addban <mask> - Adds the specified mask to the bot ban list (this doesn't do any sanity checks, so you can end up banning everyone)
#
##########
# END OF COMMANDS
##########

##########
# CONFIGURATION
##########
# Currently you only need to change the trigger (aka prefix)
# for your eggdrop commands

set banstriga "@"

##########
# END OF CONFIGURATION
##########

###############
# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
###############
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
###############

proc getBanTriga {} {
  global banstriga
  return $banstriga
}

bind pub - ${banstriga}cban cban:pub
bind pub - ${banstriga}uncban uncban:pub
bind pub - ${banstriga}addban addban:pub
bind pub - ${banstriga}bans chan:bans

proc cban:pub {nick uhost hand chan text} {
	global botnick lastban
	
	set target "[lindex [split $text] 0]"
	set banmask "[maskhost [getchanhost $target $chan] 1]"
	set banreason "User has has been banned from the channel!"
	
	if {![isidentified $nick]} {
		putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
		return 0
	}
	
	if {[isidentified $nick]} {
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP to use this command."
			return 0
		}
	}
	
	if {$target eq ""} {
		putserv "PRIVMSG $chan :ERROR! Syntax: [getBanTriga]cban <nick>"
		return 0
	}
	
	if {![onchan $target $chan]} {
		putserv "PRIVMSG $chan :ERROR! $target needs to be in the channel."
		return 0
	}
	
	set lastban "$banmask"
		
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	putkick $chan $target $banreason
	pushmode $chan +b $banmask
	putserv "PRIVMSG $chan :$banmask added to the ban list for $chan"
}

proc uncban:pub {nick uhost hand chan text} {
	global botnick lastban
	
	set unbanmask "[lindex [split $text] 0]"
	
	if {![isidentified $nick]} {
		putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
		return 0
	}
	
	if {[isidentified $nick]} {
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP to use this command."
			return 0
		}
	}
	
	if {$unbanmask eq ""} {
		putserv "PRIVMSG $chan :ERROR! Syntax: [getBanTriga]uncban \[mask|last\ (removes last ban)]. Use [getBanTriga]bans to see the channel ban list."
		return 0
	}
	
	if {$unbanmask eq "last"} {
		killchanban "$chan" "$lastban"
		pushmode $chan -b $lastban
		putserv "PRIVMSG $chan :$lastban removed from the ban list for $chan"
		return 0
	}
	
	if {![isban $unbanmask $chan]} {
		putserv "PRIVMSG $chan :ERROR! $unbanmask does not exist in my database."
		return 0
	}
	
	killchanban "$chan" "$unbanmask"
	pushmode $chan -b $unbanmask
	putserv "PRIVMSG $chan :$unbanmask removed from the ban list for $chan"
}

proc addban:pub {nick uhost hand chan text} {
	global botnick
	
	set banmask [lindex [split $text] 0]
	set banreason "User has has been banned from the channel!"
	
	if {![isidentified $nick]} {
		putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
		return 0
	}
	
	if {[isidentified $nick]} {
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP to use this command."
			return 0
		}
	}
	
	if {$banmask eq ""} {
		putserv "PRIVMSG $chan :ERROR! Syntax: [getBanTriga]addban <mask>"
		return 0
	}
	
	if {[matchstr $banmask "*!*@*"]} {
		putserv "PRIVMSG $chan :ERROR! That mask is too broad and therefore is denied"
		return 0
	}
	
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	pushmode $chan +b $banmask
	putserv "PRIVMSG $chan :$banmask added to the ban list for $chan"
}

proc chan:bans {nick uhost hand chan text} {
	global botnick
	
	if {![isidentified $nick]} {
		putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
		return 0
	}
	
	if {[isidentified $nick]} {
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP to use this command."
			return 0
		}
	}
	
	putquick "PRIVMSG $chan :BANLIST for $chan sent to $nick"
	
	foreach botban [banlist $chan] {
		set banmask [lindex [split $botban] 0]
		set creator [lindex [split $botban] end]
		putserv "PRIVMSG $nick :\002BanMask:\002 $banmask - \002Creator:\002 $creator"
	}
	return 0
}

putlog "CBan v1 @ 20/06/2020 - Loaded"
