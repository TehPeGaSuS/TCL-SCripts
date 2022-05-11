##########
# Script version and date
##########
set scriptname "Chanban.tcl v1.3a (11/05/2022)"

##########
# Based on ist0k original script (https://github.com/ist0k/eggdrop-TCL/blob/master/bans.tcl)
##########
# Public Commands:
# bancmds <= shows the list of commands.
# bans <=- shows channel ban list.
# stickbans <=- shows channel stick ban list.
# addban <nick|banmask> [reason] <=- adds a channel ban (reason is optional).
# delban <banmask.etc> <=- removes a channel ban.
# sticky <nick|banmask> [reason] <=- adds a sticky or make an existing ban sticky (reason is optional).
# delsticky <banmask> <=- removes a stick ban (without removing it from the ban list).
##########
# MSG Commands
# bancmds <#chan> <= shows the list of commands (chan is needed to check access).
# bans #channel <=- shows channel ban list.
# stickbans #channel <=- shows channel stick ban list.
# addban <nick|banmask> [reason] <=- adds a channel ban (reason is optional).
# delban <banmask> <=- removes a channel ban.
# sticky <nick|banmask> [reason] <=- adds a sticky or make an existing ban sticky (reason is optional).
# delsticky <banmask> <=- removes a stick ban (without removing it from the ban list).
##########

# Set global command trigger (default: !)
set banstriga "@"

# Set global access flags to use these commands (default: o)
# This global access flag is able to use: !bans, !stickbans, !addban, !delban, !sticky, !delsticky
set banglobflags "m"

# Set channel access flags to use these commands (default: m)
# This channel access flag is only able to use: !bans, !stickbans, !addban, !delban, !sticky, !delsticky
set banchanflags "o"

# Set the default ban reason for when banning the user
set defbanreason "User has been banned from the channel."

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

bind pub - ${banstriga}bancmds chan:bancmds
proc chan:bancmds {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bancmds <#channel>"
		return
	}
	
	putserv "PRIVMSG $chan :${nick}: The available commands are [getBanTriga]bans, [getBanTriga]stickbans, [getBanTriga]addban, [getBanTriga]delban, [getBanTriga]sticky, [delsticky]"
	return
}

bind msg - bancmds msg:bancmds
proc msg:bancmds {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 1]
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	putserv "PRIVMSG $chan :${nick}: The available commands are [getBanTriga]bans, [getBanTriga]stickbans, [getBanTriga]addban, [getBanTriga]delban, [getBanTriga]sticky, [delsticky]"
	return
}
	

bind pub - ${banstriga}bans chan:bans
proc chan:bans {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	putserv "PRIVMSG $chan :\002BANLIST\002 for $chan sent to $nick"
	putserv "PRIVMSG $nick :********** \002$chan BanList\002 **********"
	foreach botban [banlist $chan] {
		set banmask "[lindex [split $botban] 0]"
		set creator "[lindex [split $botban] end]"
		putserv "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator"
	}
	putserv "PRIVMSG $nick :********** \002$chan BanList \037END\037\002 **********"
}

bind msg - bans ban:list
proc ban:list {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 0]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bans <#channel>"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access"
		return
	}
	
	putserv "PRIVMSG $nick :********** \002$chan Ban List\002 **********"
	foreach chanban [banlist $chan] {
		set banmask "[lindex [split $chanban] 0]"
		set creator "[lindex [split $chanban] end]"
		putserv "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator"
	}
	putserv "PRIVMSG $nick :********** \002$chan Ban List \037END\037\002 **********"
	return 0
}

bind pub - ${banstriga}stickbans chan:stickbans
proc chan:stickbans {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	putserv "PRIVMSG $chan :\002STICK BANLIST\002 for $chan sent to $nick"
	putserv "PRIVMSG $nick :********** \002$chan Stick BanList\002 **********"
	foreach botban [banlist $chan] {
		if {[isbansticky $botban $chan]} {
			set banmask "[lindex [split $botban] 0]"
			set creator "[lindex [split $botban] end]"
			putserv "PRIVMSG $nick :\002Stick BanMask\002: $banmask - \002Added by:\002 $creator"
		}
	}
	putserv "PRIVMSG $nick :********** \002$chan Stick BanList \037END\037\002 **********"
}

bind msg - stickbans stickban:list
proc stickban:list {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 0]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: stickbans <#channel>"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access"
		return
	}
	
	putserv "PRIVMSG $nick :********** \002$chan Stick Ban List\002 **********"
	foreach chanban [banlist $chan] {
		if {[isbansticky $chanban $chan]} {
			set banmask "[lindex [split $chanban] 0]"
			set creator "[lindex [split $chanban] end]"
			putserv "PRIVMSG $nick :\002Stick BanMask\002: $banmask - \002Added by:\002 $creator"
		}
	}
	putserv "PRIVMSG $nick :********** \002$chan Stick Ban List \037END\037\002 **********"
	return 0
}

bind pub - ${banstriga}addban banint:pub
proc banint:pub {nick uhost hand chan text} {
	global banglobflags banchanflags defbanreason cbantype
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	set target [lindex [split $text] 0]
	set reason [join [lrange $text 1 end]]
	
	if {$target eq ""} {
		putserv "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]addban <nick|banmask> \[reason\]"
	}
	
	if {$reason eq ""} {
		set banreason $defbanreason
	} else {
		set banreason $reason
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		putserv "PRIVMSG $chan :\037ERROR\037: Banmask already exists."
		return
	}
	
	putserv "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	putserv "PRIVMSG $nick :Successfully Added Ban: $banmask for $chan"
	putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]delban $banmask"
	
	return 0
}

bind msg - addban banint:msg
proc banint:msg {nick uhost hand text} {
	global banglobflags banchanflags defbanreason cbantype
	
	set chan [lindex [split $text] 0]
	set target [lindex [split $text] 1]
	set reason [join [lrange $text 2 end]]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: addban #chan <nick|banmask> \[reason\]"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	if {$target eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: addban #chan <nick|banmask> \[reason\]"
		return
	}
	
	if {$reason eq ""} {
		set banreason $defbanreason
	} else {
		set banreason $reason
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Banmask already exists."
		return
	}
	
	putserv "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0
	putserv "PRIVMSG $nick :Successfully Added Ban: $banmask for $chan"
	putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: delban $banmask"
	
	return 0
}

bind pub - ${banstriga}sticky stick:pub
proc stick:pub {nick uhost hand chan text} {
	global banglobflags banchanflags defbanreason cbantype
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	set target [lindex [split $text] 0]
	set reason [join [lrange $text 1 end]]
	
	if {$target eq ""} {
		putserv "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]sticky <nick|banmask> \[reason\]"
	}
	
	if {$reason eq ""} {
		set banreason $defbanreason
	} else {
		set banreason $reason
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		if {![isbansticky $banmask $chan]} {
			putserv "MODE $chan +b $banmask"
			stickban "$banmask" $chan
			putserv "PRIVMSG $nick :Successfully Added Stick Ban: $banmask for $chan"
			putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]delsticky $banmask"
		} else {
			putserv "PRIVMSG $chan :\037ERROR\037: Banmask is already sticky."
			return
		}
	}
	
	putserv "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0 "sticky"
	putserv "PRIVMSG $nick :Successfully Added Stick Ban: $banmask for $chan"
	putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: [getBanTriga]delsticky $banmask"
	
	return 0
}

bind msg - sticky stick:msg
proc stick:msg {nick uhost hand text} {
	global banglobflags banchanflags defbanreason cbantype
	
	set chan [lindex [split $text] 0]
	set target [lindex [split $text] 1]
	set reason [join [lrange $text 2 end]]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: sticky #chan <nick|banmask> \[reason\]"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	if {$target eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: sticky #chan <nick|banmask> \[reason\]"
		return
	}
	
	if {$reason eq ""} {
		set banreason $defbanreason
	} else {
		set banreason $reason
	}
	
	if {[onchan $target $chan]} {
		set banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
	} else {
		set banmask "$target"
	}
	
	if {[isban $banmask $chan]} {
		if {![isbansticky $banmask $chan]} {
			putserv "MODE $chan +b $banmask"
			stickban "$banmask" $chan
			putserv "PRIVMSG $nick :Successfully Added Stick Ban: $banmask for $chan"
			putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: delsticky $banmask"
		} else {
			putserv "PRIVMSG $nick :\037ERROR\037: Banmask is already sticky."
			return
		}
	}
	
	set banreason [join $defbanreason]
	
	putserv "MODE $chan +b $banmask"
	newchanban "$chan" "$banmask" "$nick" "$banreason" 0 "sticky"
	putserv "PRIVMSG $nick :Successfully Added Stick Ban: $banmask for $chan"
	putserv "PRIVMSG $nick :If this banmask isn't accurate, remove it with: delsticky $banmask"
	
	return 0
}

bind pub - ${banstriga}delban unbanint:pub
proc unbanint:pub {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	set unbanmask [lindex [split $text] 0]
	
	if {$unbanmask eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]delban <banmask>"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putserv "PRIVMSG $chan :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	killchanban $chan $unbanmask
	putserv "PRIVMSG $nick :Successfully Deleted Ban: $unbanmask for $chan"
	return 0
}

bind msg - delban unbanint:msg
proc unbanint:msg {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 0]	
	set unbanmask [lindex [split $text] 1]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delban #chan <banmask>"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	if {$unbanmask eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delban #chan <banmask>"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	killchanban $chan $unbanmask
	putserv "PRIVMSG $nick :Successfully Deleted Ban: $unbanmask for $chan"
	return 0
}

bind pub - ${banstriga}delsticky unstick:pub
proc unstick:pub {nick uhost hand chan text} {
	global banglobflags banchanflags
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $chan :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	set unbanmask [lindex [split $text] 0]
	
	if {$unbanmask eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [getBanTriga]delsticky <banmask>"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putserv "PRIVMSG $chan :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	if {![isbansticky $unbanmask $chan]} {
		putserv "PRIVMSG $chan :\037ERROR\037: $unbanmask is not sticky."
		return
	}
	
	unstickban $unbanmask $chan
	putserv "PRIVMSG $nick :Successfully Deleted Stick Ban: $unbanmask for $chan"
	putserv "PRIVMSG $nick :If you want to rremove the ban completely, type: [getBanTriga]delban $unbanmask"
	return 0
}

bind msg - delsticky unstick:msg
proc unstick:msg {nick uhost hand text} {
	global banglobflags banchanflags
	
	set chan [lindex [split $text] 0]	
	set unbanmask [lindex [split $text] 1]
	
	if {![matchstr "#*" $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delsticky #chan <banmask>"
		return
	}
	
	if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
		putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
		return
	}
	
	if {$unbanmask eq ""} {
		putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delsticky #chan <banmask>"
		return
	}
	
	if {![isban $unbanmask $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: Banmask \002$unbanmask\002 not found."
		return
	}
	
	if {![isbansticky $unbanmask $chan]} {
		putserv "PRIVMSG $nick :\037ERROR\037: $unbanmask is not sticky."
		return
	}
	
	unstickban $unbanmask $chan
	putserv "PRIVMSG $nick :Successfully Deleted Stick Ban: $unbanmask for $chan"
	putserv "PRIVMSG $nick :If you want to remove the ban completely, type: [getBanTriga]delban $unbanmask"
	return 0
}

putlog ".: $scriptname by PeGaSuS loaded :."
