namespace eval chanban {
	##########
	# Script version and date
	##########
	variable scriptname "ChanBan v1.6.2c (20/11/2022)"

	##########
	# Based on ist0k original script (https://github.com/ist0k/eggdrop-TCL/blob/master/bans.tcl)
	##########
	# Public Commands:
	# bancmds - shows the list of commands.
	# banlist - shows channel ban list.
	# addban <nick|banmask> [reason] - adds a channel ban (reason is optional).
	# kb <nick|banmask> [reason] - same as `addban`
	# delban <banmask.etc> - removes a channel ban.
	# ub <banmask.etc> - same as delban`
	# sticky <nick|banmask> [reason] - adds a sticky or make an existing ban sticky (reason is optional).
	# delsticky <banmask> - removes a stick ban (without removing it from the ban list).
	# gag - sets a ban without kicking and therefore muting the user
	# ungag - removes a gag
	# tban <nick> <duration in hours (1-24)> - adds a channel temp ban with the specified duration
	##########
	# MSG Commands
	# bancmds <#channel> - shows the list of commands (chan is needed to check access).
	# banlist <#channel> - shows channel ban list.
	# addban <#channel> <nick|banmask> [reason] - adds a channel ban (reason is optional).
	# kb <#channel> <nick|banmask> [reason] - same as `addban`
	# delban <#channel> <banmask> - removes a channel ban.
	# ub <#channel> <banmask> - same as `delban`
	# sticky <#channel> <nick|banmask> [reason] - adds a sticky or make an existing ban sticky (reason is optional).
	# delsticky <#channel> <banmask> - removes a stick ban (without removing it from the ban list).
	# gag <#channel> <nick> - sets a ban without kicking and therefore muting the user
	# ungag <#channel> <nick> - removes a gag
	# tban <#channel> <nick> <duration in hours (1-24)> - adds a channel temp ban with the specified duration
	##########

	# Set global command trigger (default: !)
	variable banstriga "@"

	# Set global access flags to use these commands (default: o)
	# This global access flag is able to use: !bans, !stickbans, !addban, !delban, !sticky, !delsticky
	variable banglobflags "m"

	# Set channel access flags to use these commands (default: m)
	# This channel access flag is only able to use: !bans, !stickbans, !addban, !delban, !sticky, !delsticky
	variable banchanflags "o"

	# Set the default ban reason for when banning the user
	variable defbanreason "User has been banned from the channel."

	# Temporary ban default duration (minimum 10 minutes)
	variable deftbanduration "10"

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
	variable cbantype "2"

	###############
	# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
	###############
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
	###############

	proc getBanTriga {} {
		variable ::chanban::banstriga
		return $::chanban::banstriga
	}

	bind pub - ${::chanban::banstriga}bancmds ::chanban::chan:bancmds
	proc chan:bancmds {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		putserv "PRIVMSG $chan :\002\[$nick\]\002 The available commands are: [::chanban::getBanTriga]banlist, [::chanban::getBanTriga]addban OR [::chanban::getBanTriga]kb, [::chanban::getBanTriga]delban OR [::chanban::getBanTriga]ub, [::chanban::getBanTriga]sticky, [::chanban::getBanTriga]delsticky, [::chanban::getBanTriga]gag, [::chanban::getBanTriga]ungag and [::chanban::getBanTriga]tban"
		return 0
	}

	bind msg - bancmds ::chanban::msg:bancmds
	proc msg:bancmds {nick uhost hand text} {
		variable banglobflags
		variable banchanflags

		variable chan [lindex [split $text] 0]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bancmds <#channel>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bancmds <#channel>"
			return 0
		}
		
		if {![validchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
			return 0
		}

		putserv "PRIVMSG $nick :The available commands are: banlist <#channel>, addban <#channel> OR kb <#channel>, delban <#channel> OR ub <#channel>, sticky <#channel>, delsticky <#channel>, gag <#channel> <nick>, ungag <#channel> <nick> and tban <#channel> <nick> <duration in hours (1-24)"
		return 0
	}


	bind pub - ${::chanban::banstriga}banlist ::chanban::chan:bans
	proc chan:bans {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		putserv "PRIVMSG $chan :\002BANLIST\002 for $chan sent to $nick"
		putserv "PRIVMSG $nick :********** \002$chan BanList\002 **********"
		foreach botban [banlist $chan] {
			variable banmask "[lindex $botban 0]"
			if {[isbansticky $banmask $chan]} {
				variable status "Yes"
			} else {
				variable status "No"
			}
			variable creator "[lindex $botban end]"
			putserv "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator - \002Sticky:\002 $status"
		}
		putserv "PRIVMSG $nick :********** \002$chan BanList \037END\037\002 **********"
		return 0
	}

	bind msg - banlist ::chanban::ban:list
	proc ban:list {nick uhost hand text} {
		variable banglobflags
		variable banchanflags

		variable chan [lindex [split $text] 0]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bans <#channel>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: bans <#channel>"
			return 0
		}
		
		if {![validchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access"
			return 0
		}

		putserv "PRIVMSG $nick :********** \002$chan Ban List\002 **********"
		foreach chanban [banlist $chan] {
			variable banmask "[lindex [split $chanban] 0]"
			if {[isbansticky $banmask $chan]} {
				variable status "Yes"
			} else {
				variable status "No"
			}
			variable creator "[lindex [split $chanban] end]"
			putserv "PRIVMSG $nick :\002BanMask\002: $banmask - \002Added by:\002 $creator - \002Sticky:\002 $status\002"
		}
		putserv "PRIVMSG $nick :********** \002$chan Ban List \037END\037\002 **********"
		return 0
	}

	bind pub - ${::chanban::banstriga}addban ::chanban::banint:pub
	proc banint:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		variable target [lindex [split $text] 0]
		variable reason [join [lrange $text 1 end]]

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]addban <nick|banmask> \[reason\]"
			return 0
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			variable banmask "$target"
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$banreason" 0
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Added Ban: $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If this banmask isn't accurate, remove it with: [::chanban::getBanTriga]delban $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If you want to keep this banmask sticky, type: [::chanban::getBanTriga]sticky $banmask"
		return 0
	}
	
	bind msg - addban ::chanban::banint:msg
	proc banint:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		variable reason [lrange $text 2 end]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: addban #chan <nick|banmask> \[reason\]"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: addban #chan <nick|banmask> \[reason\]"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: addban #chan <nick|banmask> \[reason\]"
			return 0
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			variable banmask "$target"
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$banreason" 0
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Added Ban: $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If this banmask isn't accurate, remove it with: delban $chan $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If you want to keep this banmask sticky, type: sticky $chan $banmask"
		return 0
	}
	
	bind pub - ${::chanban::banstriga}kb ::chanban::kb:pub
	proc kb:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		variable target [lindex [split $text] 0]
		variable reason [join [lrange $text 1 end]]

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]kb <nick|banmask> \[reason\]"
			return 0
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			variable banmask "$target"
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$banreason" 0
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Added Ban: $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If this banmask isn't accurate, remove it with: [::chanban::getBanTriga]ub $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If you want to keep this banmask sticky, type: [::chanban::getBanTriga]sticky $banmask"
		return 0
	}
	
	bind msg - kb ::chanban::kb:msg
	proc kb:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		variable reason [lrange $text 2 end]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: kb #chan <nick|banmask> \[reason\]"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: kb #chan <nick|banmask> \[reason\]"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: kb #chan <nick|banmask> \[reason\]"
			return 0
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			variable banmask "$target"
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$banreason" 0
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Added Ban: $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If this banmask isn't accurate, remove it with: ub $chan $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If you want to keep this banmask sticky, type: sticky $chan $banmask"
		return 0
	}

	bind pub - ${::chanban::banstriga}sticky ::chanban::stick:pub
	proc stick:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return
		}

		variable target [lindex [split $text] 0]
		variable reason [join [lrange $text 1 end]]

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]sticky <nick|banmask> \[reason\]"
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"

			if {[isban $banmask $chan]} {
				if {![isbansticky $banmask $chan]} {
					putserv "MODE $chan +b $banmask"
					stickban "$banmask" $chan
					putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Added Stick Ban: $banmask"
					putserv "PRIVMSG $chan :\002\[$nick\]\002 If this banmask isn't accurate, remove it with: [::chanban::getBanTriga]delsticky $banmask"
					return 0
				} else {
					putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: $banmask is already sticky."
					return 0
				}
			}

			putserv "MODE $chan +b $banmask"
			newchanban "$chan" "$banmask" "$nick" "$banreason" 0 "sticky"
			putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Added Stick Ban: $banmask"
			putserv "PRIVMSG $chan :\002\[$nick\]\002 If this banmask isn't accurate, remove it with: [::chanban::getBanTriga]delsticky $banmask"
			return 0
		} else {
			variable banmask2 $target

			if {![isban $banmask2 $chan]} {
				putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]sticky <nick|banmask> \[reason\]"
				putserv "PRIVMSG $chan :\002\[$nick\]\002 To see the banmasks, type [::chanban::getBanTriga]banlist"
				return 0
			}
		}
	}

	bind msg - sticky ::chanban::stick:msg
	proc stick:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		variable reason [join [lrange $text 2 end]]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: sticky #chan <nick|banmask> \[reason\]"
			return
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: sticky #chan <nick|banmask> \[reason\]"
			return
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\037ERROR!\037 You don't have access, ${nick}!"
			return
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: sticky #chan <nick|banmask> \[reason\]"
			return
		}

		if {$target eq "*!*@*"} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: That ban is not allowed!"
			return 0
		}

		if {$reason eq ""} {
			variable banreason $defbanreason
		} else {
			variable banreason $reason
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"

			if {[isban $banmask $chan]} {
				if {![isbansticky $banmask $chan]} {
					putserv "MODE $chan +b $banmask"
					stickban "$banmask" $chan
					putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Added Stick Ban: $banmask"
					putserv "PRIVMSG $nick :\002\[$chan\]\002 If this banmask isn't accurate, remove it with: delsticky $chan $banmask"
					return 0
				} else {
					putserv "PRIVMSG $nick :\037ERROR\037: $banmask is already sticky."
					return 0
				}
			}

			putserv "MODE $chan +b $banmask"
			newchanban "$chan" "$banmask" "$nick" "$banreason" 0 "sticky"
			putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Added Stick Ban: $banmask"
			putserv "PRIVMSG $nick :\002\[$chan\]\002 If this banmask isn't accurate, remove it with: delsticky $chan $banmask"
			return 0

		} else {
			variable banmask2 $target

			if {![isban $banmask2 $chan]} {
				putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]sticky <nick|banmask> \[reason\]"
				putserv "PRIVMSG $nick :\002\[$chan\]\002 To see the banmasks, type [::chanban::getBanTriga]banlist"
				return 0
			}
		}
	}

	bind pub - ${::chanban::banstriga}delban ::chanban::unbanint:pub
	proc unbanint:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return
		}

		variable unbanmask [lindex [split $text] 0]

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]delban <banmask>"
			return
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return
		}

		killchanban $chan $unbanmask
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Deleted Ban: $unbanmask"
		return 0
	}
	
	bind msg - delban ::chanban::unbanint:msg
	proc unbanint:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags

		variable chan [lindex [split $text] 0]
		variable unbanmask [lindex [split $text] 1]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delban #chan <banmask>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delban #chan <banmask>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delban #chan <banmask>"
			return 0
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return 0
		}

		killchanban $chan $unbanmask
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Deleted Ban: $unbanmask"
		return 0
	}
	
	bind pub - ${::chanban::banstriga}ub ::chanban::ub:pub
	proc ub:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return
		}

		variable unbanmask [lindex [split $text] 0]

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]ub <banmask>"
			return
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return
		}

		killchanban $chan $unbanmask
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Deleted Ban: $unbanmask"
		return 0
	}
	
	bind msg - ub ::chanban::ub:msg
	proc ub:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags

		variable chan [lindex [split $text] 0]
		variable unbanmask [lindex [split $text] 1]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ub #chan <banmask>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ub #chan <banmask>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ub #chan <banmask>"
			return 0
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return 0
		}

		killchanban $chan $unbanmask
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Deleted Ban: $unbanmask"
		return 0
	}

	bind pub - ${::chanban::banstriga}delsticky ::chanban::unstick:pub
	proc unstick:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		variable unbanmask [lindex [split $text] 0]

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]delsticky <banmask>"
			return 0
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return 0
		}

		if {![isbansticky $unbanmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: $unbanmask is not sticky."
			return 0
		}

		unstickban $unbanmask $chan
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Deleted Stick Ban: $unbanmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If you want to remove the ban completely, type: [::chanban::getBanTriga]delban $unbanmask"
		return 0
	}

	bind msg - delsticky ::chanban::unstick:msg
	proc unstick:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags

		variable chan [lindex [split $text] 0]
		variable unbanmask [lindex [split $text] 1]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delsticky #chan <banmask>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delsticky #chan <banmask>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: delsticky #chan <banmask>"
			return 0
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask \002$unbanmask\002 not found."
			return 0
		}

		if {![isbansticky $unbanmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: $unbanmask is not sticky."
			return 0
		}

		unstickban $unbanmask $chan
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Deleted Stick Ban: $unbanmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If you want to remove the ban completely, type: [::chanban::getBanTriga]delban $unbanmask"
		return 0
	}

	bind pub - ${::chanban::banstriga}gag ::chanban::gag
	proc gag {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return
		}

		variable target [lindex [split $text] 0]

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]gag <nick>"
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]gag <nick>"
			return 0
		}

		putserv "MODE $chan +b $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 $target is now gagged. To ungag, type: [::chanban::getBanTriga]ungag <nick>"
		return 0
	}
	
	bind msg - gag ::chanban::gag:msg
	proc gag:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: gag #chan <nick>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: gag #chan <nick>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: gag #chan <nick>"
			return 0
		}
		
		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: $target is not in the channel."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 $target is now gagged. To ungag, type: ungag $chan $target"
		return 0
	}

	bind pub - ${::chanban::banstriga}ungag ::chanban::ungag
	proc ungag {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return
		}

		variable target [lindex [split $text] 0]

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]gag <nick>"
		}

		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]ungag <nick>"
			return 0
		}

		putserv "MODE $chan -b $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 $target is now ungagged."
		return 0
	}
	
	bind msg - ungag ::chanban::ungag:msg
	proc ungag:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ungag #chan <nick>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ungag #chan <nick>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: ungag #chan <nick>"
			return 0
		}
		
		if {[onchan $target $chan]} {
			variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		} else {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: $target is not in the channel."
			return 0
		}

		putserv "MODE $chan -b $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 $target is now ungagged."
		return 0
	}
	
	bind pub - ${::chanban::banstriga}tban ::chanban::tban:pub
	proc tban:pub {nick uhost hand chan text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype
		
		variable target [lindex [split $text] 0]
		variable minutes [lindex [split $text] 1]

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]tban <nick> <duration (in hours, between 1-24)>"
			return 0
		}
		
		if {![onchan $target $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]tban <nick> <duration (in hours, between 1-24)>"
			return 0
		}
		
		variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		
		if {$minutes eq ""} {
			set bantime $::chanban::deftbanduration
		} else {
			set bantime $minutes
		}
			
		if {($minutes < "10") || ($minutes > "60")} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: [::chanban::getBanTriga]tban <nick> <duration (in minutes, between 10-60)>"
			return 0
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $chan :\002\[$nick\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$defbanreason" $bantime
		putserv "PRIVMSG $chan :\002\[$nick\]\002 Successfully Added Temp Ban: $banmask"
		putserv "PRIVMSG $chan :\002\[$nick\]\002 If this banmask isn't accurate, remove it with: [::chanban::getBanTriga]ub $banmask"
		return 0
	}
	
	bind msg - tban ::chanban::tban:msg
	proc tban:msg {nick uhost hand text} {
		variable banglobflags
		variable banchanflags
		variable defbanreason
		variable cbantype

		variable chan [lindex [split $text] 0]
		variable target [lindex [split $text] 1]
		variable minutes [lindex [split $text] 2]
		
		if {$chan eq ""} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: tban #chan <nick> <duration (in hours, between 1-24)>"
			return 0
		}

		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Incorrect Parameters. \037SYNTAX\037: tban #chan <nick> <duration (in hours, between 1-24)>"
			return 0
		}
		
		if {![validchan $chan] || ![botonchan $chan]} {
			putserv "PRIVMSG $nick :\037ERROR\037: Invalid channel name."
			return 0
		}

		if {![matchattr $hand $banglobflags|$banchanflags $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR!\037 You don't have access!"
			return 0
		}

		if {$target eq ""} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: tban #chan <nick> <duration (in hours, between 1-24)>"
			return 0
		}
		
		if {![onchan $target $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: tban #chan <nick> <duration (in hours, between 1-24)>"
			return 0
		}
		
		variable banmask "[maskhost ${target}![getchanhost $target $chan] $cbantype]"
		
		if {$hours eq ""} {
			set bantime $::chanban::deftbanduration
		} else {
			set bantime $minutes
		}
		
		if {($minutes < "10") || ($minutes > "60")} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Incorrect Parameters. \037SYNTAX\037: tban <nick> <duration (in minutes, between 10-60)>"
			return 0
		}

		if {[isban $banmask $chan]} {
			putserv "PRIVMSG $nick :\002\[$chan\]\002 \037ERROR\037: Banmask already exists."
			return 0
		}

		putserv "MODE $chan +b $banmask"
		newchanban "$chan" "$banmask" "$nick" "$defbanreason" $bantime
		putserv "PRIVMSG $nick :\002\[$chan\]\002 Successfully Added Temp Ban: $banmask"
		putserv "PRIVMSG $nick :\002\[$chan\]\002 If this banmask isn't accurate, remove it with: ub $chan $banmask"
		return 0
	}

	putlog ".: $scriptname by PeGaSuS loaded :."
};
