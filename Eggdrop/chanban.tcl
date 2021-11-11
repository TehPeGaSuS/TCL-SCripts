##########
# bans.tcl v1.0 (11/11/2021)
# Based on ist0k original script (https://github.com/ist0k/eggdrop-TCL/blob/master/bans.tcl)
##########
# Public Commands:
# bans <=- shows channel ban list.
# globans <=- shows global ban list.
# ban <nick|*!*@banmask.etc> <=- adds a channel ban.
# unban <*!*@banmask.etc> <=- removes a channel ban.
##########
# MSG Commands
# bans #channel <=- shows channel ban list.
# ban <nick|*!*@banmask.etc> <=- adds a channel ban.
# unban <*!*@banmask.etc> <=- removes a channel ban.
##########

# Set global command trigger (default: !)
set banstriga "@"

# Set global access flags to use these commands (default: o)
# This global access flag is able to use: !bans, !globans, !gban, !delgban, !addban, !delban
set banglobflags "o"

# Set channel access flags to use these commands (default: m)
# This channel access flag is only able to use: !bans, !addban, !delban (like akick, for SOP)
set banchanflags "m"

# Set the default ban reason for when banning the user
set banreason "User has been banned from the channel."

# Set the banmask to use in banning the user  
#	Available types are:
#	0 *!user@host
#	1 *!*user@host
#	2 *!*@host
#	3 *!*user@*.host
#	4 *!*@*.host
#	5 nick!user@host
#	6 nick!*user@host
#	7 nick!*@host
#	8 nick!*user@*.host
#	9 nick!*@*.host
set cbantype "2"

###############
# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
###############
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
###############

proc getBanTriga {} {
	global banstriga
	return $banstriga
}

bind pub - ${banstriga}bans chan:bans
proc chan:bans {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {[matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		putquick "PRIVMSG $chan :\002BANLIST\002 for $chan sent to $nick"
		putserv "PRIVMSG $nick :********* \002$chan BanList\002 **********"
		
		foreach botban [banlist $chan] {
			set banmask "[lindex [split $botban] 0]"
			set creator "[lindex [split $botban] end]"
			putserv "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator"
		}
		putserv "PRIVMSG $nick :********** \002$chan BanList \037END\037\002 **********"
	}
}

bind msg - bans ban:list
proc ban:list {nick uhost hand text} {
	global banglobflags banchanflags banreason
	
	set chan [lindex [split $text] 0]
	
	if {![matchstr "#*" $chan]} {
		putquick "PRIVMSG $nick :\037ERROR!\037 Syntax: bans <#channel>"
		return
	}
	
	if {[matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		putquick "PRIVMSG $nick :\037ERROR!\037 You don't have access"
		return
	}
	
	putserv "PRIVMSG $nick :********** \002$chan Ban List\002 **********"
	foreach chanban [banlist $chan] {
		set banmask "[lindex [split $chanban] 0]"
		set creator "[lindex [split $chanban] end]"
		putquick "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator"
	}
	putserv "PRIVMSG $nick :********** \002$chan Ban List \037END\037\002 **********"
	return 0
}

bind pub - ${banstriga}ban banint:pub
proc banint:pub {nick uhost hand chan text} {
	global banglobflags banchanflags banreason cbantype
	
	if {![matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		return
	}
	
	set target [lindex [split $text] 0]
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]ban <nick|*!*@banmask.etc>"
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		putquick "PRIVMSG $chan :\037ERROR\037: Banmask already exists."
		return
	}
	
	set banreason [join $banreason]
	
	putquick "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	putquick "PRIVMSG $nick :Successfully Added Ban: $banmask for $chan"
	putquick "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]unban $banmask"
	
	return 0
}

bind msg - ban banint:msg
proc banint:msg {nick uhost hand text} {
	global banglobflags banchanflags banreason cbantype
	
	set chan [lindex [split $text] 0]
	set target [lindex [split $text] 1]
	
	if {![matchstr "#*" $chan]} {
		putquick "PRIVMSG $nick :\037ERROR\037: [getBanTriga]ban #chan <nick|*!*@banmask.etc>"
		return
	}
	
	if {![matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		putquick "PRIVMSG $nick :\037ERROR!\037 You don't have access"
		return
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: [getBanTriga]ban #chan <nick|*!*@banmask.etc>"
		return
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		putquick "PRIVMSG $nick :\037ERROR\037: Banmask already exists."
		return
	}
	
	set banreason [join $banreason]
	
	putquick "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	putquick "PRIVMSG $nick :Successfully Added Ban: $banmask for $chan"
	putquick "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]unban $banmask"
	
	return 0
}

bind pub - ${banstriga}unban unbanint:pub
proc unbanint:pub {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		return
	}
	
	set unbanmask [lindex [split $text] 0]
	
	if {$unbanmask eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]unban *!*@banmask.etc"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putquick "PRIVMSG $chan :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	killchanban $chan $unbanmask
	putquick "PRIVMSG $nick :Successfully Deleted Ban: $unbanmask for $chan"
	return 0
}

bind msg - unban unbanint:msg
proc unbanint:msg {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 0]	
	set unbanmask [lindex [split $text] 1]
	
	if {![matchstr "#*" $chan]} {
		putquick "PRIVMSG $nick :\037ERROR\037: [getBanTriga]unban #chan <*!*@banmask.etc>"
		return
	}
	
	if {![matchattr [nick2hand $nick] $banglobflags|$banchanflags $chan]} {
		putquick "PRIVMSG $nick :\037ERROR!\037 You don't have access"
		return
	}
	
	if {$unbanmask eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: [getBanTriga]unban #chan <*!*@banmask.etc>"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putquick "PRIVMSG $nick :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	killchanban $chan $unbanmask
	putquick "PRIVMSG $nick :Successfully Deleted Ban: $unbanmask for $chan"
	return 0
}

bind pub - ${banstriga}gban gban:pub
proc gban:pub {nick uhost hand chan text} {
	global banglobflags banreason banreason cbantype
	
	if {![matchattr [nick2hand $nick] $banglobflags]} {
		return
	}
	
	set target [lindex [split $text] 0]
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	
	if {$banmask eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]gban <nick|*!*@banmask.etc>"
		return
	}
	
	if {[isban $banmask]} {
		putquick "PRIVMSG $nick :\037ERROR\037: Banmask already exists."
		return
	}
	
	set banreason [join $banreason]
	
	newban $banmask $nick $banreason 0
	putquick "PRIVMSG $nick :Successfully Added Global Ban: $banmask for: [channels]"
	putquick "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]ungban $banmask"
	return 0
}

bind pub - ${banstriga}ungban unbanglob:pub
proc unbanglob:pub {nick uhost hand chan text} {
	global banglobflags
	
	if {![matchattr [nick2hand $nick] $banglobflags]} {
		return
	}
	
	set unbanmask [lindex [split $text] 0]
	
	if {$unbanmask eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]ungban *!*@banmask.etc"
		return
	}
	
	if {![isban $unbanmask]} {
		putquick "PRIVMSG $nick :\037ERROR\037: Banmask not Found."
		return
	}
	
	killban $unbanmask
	putquick "PRIVMSG $nick :Successfully Deleted Global Ban: $unbanmask for: [channels]"
	return 0
}

putlog ".: Bans.tcl by PeGaSuS loaded :."
