##########
# Public Commands
##########
# Author: PeGaSuS
# IRC: irc.ptirc.org +6697 #eggdrop
# GitHub: https://github.com/PeGaSuS-Coder/TCL-SCripts
##########
# This script needs eggdrop 1.9 (currently under development).
# It won't work in lower versions.
# You need to set yourself as owner with your main IRC nickname.
# Grouped nicks will be automatically identified to the bot
# In order for this script to work properly, you need to search for the following line:
# set cap-request "feature1 feature2 feature3", uncomment it and make it:
# set cap-request "account-notify extended-join"
##########

namespace eval pubcmd {
	##########
	# Configuration
	##########
	
	##########
	# Public trigger
	##########
	variable trigger "!"
	
	##########
	# Flags
	##########
	# OWNER
	##########
	variable nflags "n|n"
	##########
	# OP
	##########
	variable oflags "o"
	##########
	# VOICE
	##########
	variable vflags "v"
	
	##########
	# IRCd Type
	##########
	# 1 - UnrealIRCd
	# 2 - InspIRCd
	# 3 - Charybdis (freenode)
	##########
	variable IRCd "3"
	
	##########
	# End of configuration
	##########
	
	##########
	# Do not edit anything below unless you know what you're doing.
	# You've been warned!!!
	##########
	
	##########
	# Binds
	##########
	bind pub - [set [namespace current]::trigger]addop [namespace current]::addop:pub
	bind pub - [set [namespace current]::trigger]addvoice [namespace current]::addvoice:pub
	bind pub - [set [namespace current]::trigger]ban [namespace current]::ban:pub
	bind pub - [set [namespace current]::trigger]unban [namespace current]::unban:pub
	
	##########
	# Procs
	##########
	
	##########
	# Add OP
	##########
	proc addop:pub {nick uhost hand chan text} {
		variable trigger; variable oflags; variable vflags; variable nflags
		
		variable nsaccount "[getaccount $nick]"
		set target "[lindex [split $text] 0]"
		variable tgtaccount "[getaccount $target]"
		variable tgthost "[maskhost ${target}![getchanhost $target $chan] 2]"
		
		if {![matchattr $nsaccount $nflags]} {
			putserv [format "PRIVMSG %s :%s, you don't have access" $chan $nick]
			return 0
		}
		
		if {$target eq ""} {
			putserv [format "PRIVMSG %s :ERROR! Syntax: %saddop <nick>" $chan $trigger]
			return 0
		}
		
		if {$tgtaccount eq ""} {
			putserv [format "PRIVMSG %s :%s isn't a registered nick" $chan $target]
			return 0
		}
		
		if {![validuser $tgtaccount]} {
			adduser $tgtaccount $tgthost
			chattr $tgtaccount |+$oflags $chan
			putserv [format "PRIVMSG %s :%s added to %s OP list" $chan $tgtaccount $chan]
			if {!([isvoice $target $chan] || [isop $target $chan])} {
				pushmode $chan +$oflags $target
				return 0
			} elseif {[isvoice $target $chan]} {
				pushmode $chan +$oflags $target
				pushmode $chan -$vflags $target
				return 0
			}
			flushmode $chan
			return 0
		}
		
		if {[validuser $tgtaccount]} {
			if {[matchattr $tgtaccount |$oflags $chan]} {
				putserv [format "PRIVMSG %s :%s is already an OP on %s." $chan $tgtaccount $chan]
				return 0
			}
			if {[matchattr $tgtaccount |$vflags $chan]} {
				putserv [format "PRIVMSG %s :%s is a VOICE in %s. Promoting to OP." $chan $tgtaccount $chan]
				chattr $tgtaccount |-$vflags $chan
				chattr $tgtaccount |+$oflags $chan
				putserv [format "PRIVMSG %s :%s added to %s OP list" $chan $tgtaccount $chan]
				if {!([isvoice $target $chan] || [isop $target $chan])} {
					pushmode $chan +$oflags $target
				} elseif {[isvoice $target $chan]} {
					pushmode $chan +$oflags $target
					pushmode $chan -$vflags $target
					return 0
				}
				flushmode $chan
				return 0
			}
			chattr $tgtaccount |+$oflags $chan
			putserv [format "PRIVMSG %s :%s added to %s OP list" $chan $tgtaccount $chan]
			if {!([isvoice $target $chan] || [isop $target $chan])} {
				pushmode $chan +$oflags $target
			} elseif {[isvoice $target $chan]} {
				pushmode $chan +$oflags $target
				pushmode $chan -$vflags $target
				return 0
			}
			flushmode $chan
			return 0
		}
		return 0
	}
	
	##########
	# Add Voice
	##########
	proc addvoice:pub {nick uhost hand chan text} {
		variable trigger; variable vflags; variable oflags; variable nflags
		
		variable nsaccount "[getaccount $nick]"
		set target "[lindex [split $text] 0]"
		variable tgtaccount "[getaccount $target]"
		variable tgthost "[maskhost ${target}![getchanhost $target $chan] 2]"
		
		if {![matchattr $nsaccount $nflags]} {
			putserv [format "PRIVMSG %s :%s, you don't have access." $chan $nick]
			return 0
		}
		
		if {$target eq ""} {
			putserv [format "PRIVMSG %s :ERROR! Syntax: %saddvoice <nick>" $chan $trigger]
			return 0
		}
		
		if {$tgtaccount eq ""} {
			putserv [format "PRIVMSG %s :%s isn't a registered nick." $chan $target]
			return 0
		}
		
		if {![validuser $tgtaccount]} {
			adduser $tgtaccount $tgthost
			chattr $tgtaccount |+$vflags $chan
			putserv [format "PRIVMSG %s :%s added to %s VOICE list" $chan $tgtaccount $chan]
			if {!([isvoice $target $chan] || [isop $target $chan])} {
				pushmode $chan +$vflags $nick
			} elseif {[isop $target $chan]} {
				pushmode $chan -$oflags $target
				pushmode $chan +$vflags $target
			}
			flushmode $chan
			return 0
		}
		
		if {[validuser $tgtaccount]} {
			if {[matchattr $tgtaccount |$vflags $chan]} {
				putserv [format "PRIVMSG %s :%s is already a VOICE on %s" $chan $tgtaccount $chan]
				return 0
			}
			if {[matchattr $tgtaccount |$oflags $chan]} {
				putserv [format "PRIVMSG %s :%s is an OP on %s. Demoting to VOICE." $chan $tgtaccount $chan]
				chattr $tgtaccount |+$vflags $chan
				chattr $tgtaccount |-$oflags $chan
				putserv [format "PRIVMSG %s :%s added to %s VOICE list" $chan $tgtaccount $chan]
				if {!([isvoice $target $chan] || [isop $target $chan])} {
					pushmode $chan +$vflags $target
					return 0
				} elseif {[isop $target $chan]} {
					pushmode $chan -$oflags $target
					pushmode $chan +$vflags $target
					return 0
				}
				flushmode $chan
				return 0
			}
			return 0
		}
	}
};

putlog "Public Comands v0.1 by PeGaSuS loaded"
