##########
# adduser-joinmodes.tcl v1.0 (11/11/2021)
# Based on ist0k original script (https://github.com/ist0k/eggdrop-TCL/blob/master/adduser-joinmodes.tcl)
##########
# Last update: 26/08/2023
##########
# ----- ADDING USERS ----- (Basic User adding)
# Commands are:
# !addaop nickname - Adds <nickname> to the bot OP list for the channel
# !delaop nickname - Removes <nickname> from the bot OP list for the channel
# !addhop nickname - Adds <nickname> to the bot HALFOP list for the channel
# !delhop nickname - Removes <nickname> from the bot HALFOP list for the channel
# !addaov nickname - Adds <nickname> to the bot VOICE list for the channel
# !delaov nickname - Removes <nickname> from the bot VOICE list for the channel
##########
# ----- JoinModes ----- (This enforces joinmodes @/+)
# JoinModes Public Commands:
# Enable:  !joinmodes on
# Disable: !joinmodes off
##########
# JoinModes Message Command:
# /msg botnick joinmodes #channel on|off
##########

# -----------EDIT BELOW------------

# Set this to whatever trigger you like. (default: !)
set addusertrig "@"

# Set the mask type to use when adding users
#	Available types are:
#	0	*!user@host
#	1	*!*user@host
#	2	*!*@host
#	3	*!*user@*.host
# 	4	*!*@*.host
#	5	nick!user@host
#	6	nick!*user@host
#	7	nick!*@host
#	8	nick!*user@*.host
#	9	nick!*@*.host
set cmasktype "3"

# You don't need to edit the access flags. They are added like this because each command requires different access.
# This is to ensure that user's can't add/del those with more access. If you wish to edit them, edit the proc directly.

# ------EDIT COMPLETE!!------

###############
# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
###############
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
###############
setudef flag joinmode

proc addTrigger {} {
	global addusertrig
	return $addusertrig
}

bind join - * join:modes
bind pub - ${addusertrig}addaop addaop:pub
bind pub - ${addusertrig}delaop delaop:pub
bind pub - ${addusertrig}addhop addhop:pub
bind pub - ${addusertrig}delhop delhop:pub
bind pub - ${addusertrig}addvop addvop:pub
bind pub - ${addusertrig}delvop delvop:pub
bind pub - ${addusertrig}joinmodes jmode:pub
bind msg - joinmodes jmode:msg


proc addaop:pub {nick uhost hand chan text} {
	global cmasktype
		
	set target [lindex [split $text] 0]
	set mask "[maskhost ${target}![getchanhost $target $chan] $cmasktype]"
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]addaop <nickname>"
		return 0
	}
	
	if {![onchan $target $chan]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not even on $chan ..."
		return 0
	}
	
	if {[validuser [nick2hand $target]] && ![matchattr [nick2hand $target] |o $chan]} {
		chattr $target |+o $chan
		putquick "MODE $chan +o $target"
		return 0
	}
	
	adduser $target $mask
	chattr $target |+o $chan
	putquick "MODE $chan +o $target"
	putquick "PRIVMSG $chan :Added $target ($mask) to the AOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has added you to the AOP List for $chan"
	return 0
}

proc delaop:pub {nick uhost hand chan text} {
	set target [lindex [split $text] 0]
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]delaop nickname"
		return 0
	}
	
	if {![validuser [nick2hand $target]]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not a valid user."
		return 0
	}
	
	set found 0
	
	foreach chans [channels] {
		if {[matchattr [nick2hand $target] |ovl $chans]} {
			set found 1
		}
	}
	
	if {$found} {
		if {![matchattr [nick2hand $target] mn]} {
			deluser $target
			putquick "MODE $chan -o $target"
		} else {
			chattr $target |-o $chan
			putquick "MODE $chan -o $target"
		}
	}
	
	putquick "PRIVMSG $chan :Deleted $target from the AOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has deleted you from the AOP List for $chan"
}

proc addhop:pub {nick uhost hand chan text} {
	global cmasktype
	
	set target [lindex [split $text] 0]
	set mask "[maskhost ${target}![getchanhost $target $chan] $cmasktype]"
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]addhop nickname"
		return
	}
	
	if {![onchan $target $chan]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not even on $chan ..."
		return
	}
	
	if {[validuser [nick2hand $target]] && ![matchattr [nick2hand $target] |l $chan]} {
		chattr $target |+l $chan
		putquick "MODE $chan +h $target"
		return 0
	}
	
	adduser $target $mask
	chattr $target |+l $chan
	putquick "MODE $chan +h $target"
	putquick "PRIVMSG $chan :Added $target ($mask) to the HOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has added you to the HOP List for $chan"
}

proc delhop:pub {nick uhost hand chan text} {
	set target [lindex [split $text] 0]
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]delhop nickname"
		return 0
	}
	
	if {![validuser [nick2hand $target]]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not a valid user."
		return 0
	}
	
	set found 0
	
	foreach chans [channels] {
		if {[matchattr [nick2hand $target] |ovl $chans]} {
			set found 1
		}
	}
	
	if {$found} {
		if {![matchattr [nick2hand $target] mn]} {
			deluser $target
			putquick "MODE $chan -h $target"
		} else {
			chattr $target |-l $chan
			putquick "MODE $chan -h $target"
		}
	}
	
	putquick "PRIVMSG $chan :Deleted $target from the HOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has deleted you from the HOP List for $chan"
}

proc addvop:pub {nick uhost hand chan text} {
	global cmasktype
	
	set target [lindex [split $text] 0]
	set mask "[maskhost ${target}![getchanhost $target $chan] $cmasktype]"
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]addvop nickname"
		return
	}
	
	if {![onchan $target $chan]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not even on $chan ..."
		return
	}
	
	if {[validuser [nick2hand $target]] && ![matchattr [nick2hand $target] |v $chan]} {
		chattr $target |+v $chan
		putquick "MODE $chan +v $target"
		return 0
	}
	
	adduser $target $mask
	chattr $target |+v $chan
	putquick "MODE $chan +v $target"
	putquick "PRIVMSG $chan :Added $target ($mask) to the VOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has added you to the VOP List for $chan"
}

proc delvop:pub {nick uhost hand chan text} {
	set target [lindex [split $text] 0]
	
	if {![matchattr [nick2hand $nick] mn]} {
		putserv "PRIVMSG $chan :Sorry ${nick}, but you don't have access!"
		return 0
	}
	
	if {$target eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]delvop nickname"
		return 0
	}
	
	if {![validuser [nick2hand $target]]} {
		putquick "PRIVMSG $chan :\037ERROR\037: $target is not a valid user."
		return 0
	}
	
	set found 0
	
	foreach chans [channels] {
		if {[matchattr [nick2hand $target] |ovl $chans]} {
			set found 1
		}
	}
	
	if {$found} {
		if {![matchattr [nick2hand $target] mn]} {
			deluser $target
			putquick "MODE $chan -v $target"
		} else {
			chattr $target |-v $chan
			putquick "MODE $chan -v $target"
		}
	}
	
	putquick "PRIVMSG $chan :Deleted $target from the VOP List for $chan"
	putquick "NOTICE $target :$nick ($hand) has deleted you from the VOP List for $chan"
}

proc jmode:pub {nick uhost hand chan text} {
	if {![matchattr [nick2hand $nick] m|o $chan]} {
		return
	}
	
	set option [strlwr [lindex [split $text] 0]]
	
	if {$option eq ""} {
		putquick "PRIVMSG $chan :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [addTrigger]joinmodes on|off"
		return
	}
	
	if {$option eq "on"} {
		if {[channel get $chan joinmode]} {
			putquick "PRIVMSG $chan :\037ERROR\037: This setting is already enabled."
		} else {
			channel set $chan +joinmode
			putquick "PRIVMSG $chan :Enabled Auto @/+ Modes for $chan"
		}
		return 0
	}
	
	if {$option eq "off"} {
		if {![channel get $chan joinmode]} {
			putquick "PRIVMSG $chan :\037ERROR\037: This setting is already disabled."
		} else {
			channel set $chan -joinmode
			puthelp "PRIVMSG $chan :Disabled Auto @/+ Modes for $chan"
		}
		return 0
	}
}

proc jmode:msg {nick uhost hand text} {
	global botnick
	
	set chan [strlwr [lindex [split $text] 0]]
	
	set option [strlwr [lindex [split $text] 1]]
	
	if {![matchattr [nick2hand $nick] m]} {
		return
	}
	
	if {![matchstr "#*" $chan]} {
		putquick "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: /msg $botnick joinmodes #channel on|off"
		return
	}
	
	if {$option eq ""} {
		putquick "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: /msg $botnick joinmodes #channel on|off"
		return
	}
	
	if {$option eq "on"} {
		if {[channel get $chan joinmode]} {
			putserv "PRIVMSG $nick :\037ERROR\037: This setting is already enabled."
		} else {
			channel set $chan +joinmode
		}
		return 0
	}
	
	if {$option eq "off"} {
		if {![channel get $chan joinmode]} {
			 putserv "PRIVMSG $nick :\037ERROR\037: This setting is already disabled."
		 } else {
			 channel set $chan -joinmode
		 }
		 return 0
	 }
 }

proc join:modes {nick uhost hand chan} {
	global botnick
	
	if {([string tolower $nick] ne [string tolower $botnick])} {
		if {([channel get $chan joinmode] && [botisop $chan])} {
			if {[matchattr [nick2hand $nick] |o $chan]} {
				putquick "MODE $chan +o $nick"
				return 0
			}
			
			if {[matchattr [nick2hand $nick] |l $chan]} {
				putquick "MODE $chan +h $nick"
				return 0
			}
			
			if {[matchattr [nick2hand $nick] |v $chan]} {
				putquick "MODE $chan +v $nick"
				return 0
			}
		}
	}
}

putlog ".: AddUSER+JoinMODEs v1.3 by PeGaSuS loaded :."
