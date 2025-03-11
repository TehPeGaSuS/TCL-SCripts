###############
# KickBan TCL #
###############

##########
# Changelog
##########
# 20/06/2020
# -= v1 =-
# - Initial release
##########
# 28/06/2020
# -= v2 =-
# - Converted the script into a namespace
# - Added temporary ban command, default ban reason and ban duration (for temp ban)
##########
# 28/06/2020
# -= v2.1 =-
# - Added some bot protections
##########
# 10/02/2021
# -= v2.2 =-
# - Removed unused vars
# - Code cleanup
# - Syntax fixing
#
# -= v2.3 =-
# - Added the possibility to remotely add/remove/check bans (via private msg)
##########
# 19/02/2021
# -= v2.4 =-
# - Added kick command
# - Added PM commands to help keep anonymity
# - Fixed logic within procedures to be more resilient
# - More code cleanup
##########
# 01/09/2024
# - Huge code cleanup
##########

##########
# COMMANDS
##########
# - NOTE: the #chan variable is mandatory on private message commands
#
##########
# Public commands
########## 
# - cban <nick> - bans the nick in the format *!*user@host (nick needs to be in the channel)
#
# - tban <nick> - Adds a temporary ban in the specified nick (nick must be on channel) with the duration
#   specified on banDuration variable
#
# - addban <mask> - Adds the specified mask to the bot ban list (this doesn't do any sanity checks, so you can end up banning everyone)
#
# - kick <nick> - Kicks someone from the channel
#
# - uncban <mask> - Removes the specified mask
#
# - bans - Sends a PM to the user showing the current internal ban list for the channel
#
##########
# PM commands
##########
# - cban <#chan> <nick> - bans the nick in the format *!*user@host (nick needs to be in the channel)
#
# - uncban <#chan> <mask> - Removes the specified mask
#
# - bans <#chan> - Sends a PM to the user showing the current internal ban list for the channel
#
# - addban <#chan> <mask> - Adds the specified mask to the bot ban list (this doesn't do any sanity checks, so you can end up banning everyone)
#
# - tban <#chan> <nick> - Adds a temporary ban in the specified nick (nick must be on channel) with the duration
#   specified on banDuration variable
#
# - kick <#chan> <nick> - Kicks someone from the specified channel
#
##########
# END OF COMMANDS
##########
namespace eval cban {

	##########
	# CONFIGURATION
	##########
	# Trigger for the command
	variable banTrigger "@"

	# Default ban reason
	variable banReason "User has has been banned from the channel!"
	
	# Default kick reason
	variable kickReason "Your behaviour is not conducive for the desired environment!"

	# How many minutes for the temp ban
	variable banDuration "10"
	
	# Revenge kick reason when someone tries to ban the bot (%s will be replaced by the nick of
	# the person that tried to ban the bot)
	variable revengeBan "\002\00304Revenge Ban#\003\002 You wish %s! Next time, try to ban \00305yourself\003!"
	
	# Revenge kick reason when someone tries to kick the bot (%s will be replaced by the nick that
	# tried to kick the bot)
	variable revengeKick "\002\00304Revenge Kick#\003\002 You wish %s! Next time, try to kick \00305yourself\003!"

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
	variable banType "2"
	
	##########
	# END OF CONFIGURATION
	##########

	###############
	# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
	###############
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
	###############
	
	################
	# Public binds #
	################
	bind pub - ${banTrigger}cban ::cban::cban:pub
	bind pub - ${banTrigger}uncban ::cban::uncban:pub
	bind pub - ${banTrigger}addban ::cban::addban:pub
	bind pub - ${banTrigger}tban ::cban::tban:pub
	bind pub - ${banTrigger}kick ::cban::kick:pub
	bind pub - ${banTrigger}bans ::cban::bans:pub
	
	#########################
	# Private message binds #
	#########################
	bind msg - cban ::cban::cban:msg
	bind msg - uncban ::cban::uncban:msg
	bind msg - addban ::cban::addban:msg
	bind msg - tban ::cban::tban:msg
	bind msg - kick ::cban::kick:msg
	bind msg - bans ::cban::bans:msg
	
	################
	# Public procs #
	################
	
	# @cban
	proc cban:pub {nick uhost hand chan text} {
		set target "[lindex [split $text] 1]"		
		
		if {([matchstr "uid*" [string trim [getchanhost $target $chan] ~]] || [matchstr "sid*" [string trim [getchanhost $target $chan] ~]])} {
			set banmask "[maskhost ${target}![getchanhost $target $chan] 3]"
		} else {
			set banmask "[maskhost ${target}![getchanhost $target $chan] $::cban::banType]"
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $chan :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
		}

		if {$target eq "" || ![onchan $target $chan]} {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::cban::banTrigger}cban <nick>"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}

		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" 0
		putserv "PRIVMSG $chan :Added $banmask to $chan ban list."
		return 0
	}

	
	# @tban
	proc tban:pub {nick uhost hand chan text} {
		set target "[lindex [split $text] 0]"
		
		if {([matchstr "uid*" [string trim [getchanhost $target $chan] ~]] || [matchstr "sid*" [string trim [getchanhost $target $chan] ~]])} {
			set banmask "[maskhost ${target}![getchanhost $target $chan] 3]"
		} else {
			set banmask "[maskhost ${target}![getchanhost $target $chan] $::cban::banType]"
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $chan :ERROR! I'm not OP on $chan"
			return 0
		}

		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
		}

		if {$target eq "" || ![onchan $target $chan]} {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::cban::banTrigger}tban <nick>"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}

		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" $::cban::banDuration
		putserv "PRIVMSG $chan :Temporarily banned $banmask on $chan"
		return 0
	}
	
	# @addban
	proc addban:pub {nick uhost hand chan text} {
		set banmask "[lindex [split $text] 0]"
				
		if {![botisop $chan]} {
			putserv "PRIVMSG $chan :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
			}
		
		if {$banmask eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::cban::banTrigger}addban <mask>"
			return 0
		}

		if {$banmask eq "*!*@*"} {
			putserv "PRIVMSG $chan :ERROR! That mask is too broad. Try something more specific."
			return 0
		}
		
		if {[matchstr $banmask $::botname]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}
		
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" 0
		putserv "PRIVMSG $chan :Added $banmask to $chan ban list."
		return 0
	}
	
	# @kick
	proc kick:pub {nick uhost hand chan text} {
		set target "[lindex [split $text] 0]"
			
		if {![botisop $chan]} {
			putserv "PRIVMSG $chan :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {$target eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::cban::banTrigger}kick <nick>"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeKick $nick]
			return 0
		}
		
		putkick $chan $target $::cban::kickReason
		return 0
	}
	
	# @uncban
	proc uncban:pub {nick uhost hand chan text} {
		set unbanmask "[lindex [split $text] 0]"
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $chan :ERROR! I'm not OP on $chan"
			return 0
		}

		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
			}
		
		if {$unbanmask eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::cban::banTrigger}uncban <mask>. Use ${::cban::banTrigger}bans to see the channel ban list."
			return 0
		}

		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $chan :ERROR! $unbanmask does not exist in my database."
			return 0
		}

		killchanban "$chan" "$unbanmask"
		pushmode $chan -b $unbanmask
		putserv "PRIVMSG $chan :$unbanmask removed from the ban list for $chan"
		return 0
	}
	
	# @bans
	proc bans:pub {nick uhost hand chan text} {
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
				
		if {[banlist $chan] eq ""} {
			putserv "PRIVMSG $chan :There are no bans on $chan"
			return 0
		}

		putquick "PRIVMSG $chan :BANLIST for $chan sent to $nick"

		foreach botban [banlist $chan] {
			set banmask "[lindex [split $botban] 0]"
			set creator "[lindex [split $botban] end]"
			putserv "PRIVMSG $nick :\002BanMask:\002 $banmask - \002Creator:\002 $creator"
		}
		return 0
	}
	
	#################
	# Private procs #
	#################
	
	# cban
	proc cban:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		set target "[lindex [split $text] 1]"
		
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: cban <#chan> <nick>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not on $chan or $chan is set as inactive."
			return 0
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $nick :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {$target eq ""} {
			putserv "PRIVMSG $nick :ERROR! Syntax: cban <#chan> <nick>"
			return 0
		}
		
		if {![onchan $target $chan]} {
			putserv "PRIVMSG $nick :ERROR! $target needs to be on $chan"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}
		
		if {[matchstr "*.irccloud.com" [getchanhost $target $chan]]} {
			set banmask "[maskhost ${target}![getchanhost $target $chan] 3]"
		} else {
			set banmask "[maskhost ${target}![getchanhost $target $chan] $::cban::banType]"
		}
		
		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" 0
		putserv "PRIVMSG $nick :$banmask added to $chan ban list."
		return 0
	}
	
	# tban
	proc tban:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		set target "[lindex [split $text] 1]"
			
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: tban <#chan> <nick>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not on $chan or $chan is set as inactive."
			return 0
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $nick :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {$target eq ""} {
			putserv "PRIVMSG $nick :ERROR! Syntax: tban <#chan> <nick>"
			return 0
		}
		
		if {![onchan $target $chan]} {
			putserv "PRIVMSG $nick :ERROR! $target needs to be on $chan"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}
		
		if {[matchstr "*.irccloud.com" [getchanhost $target $chan]]} {
			set banmask "[maskhost ${target}![getchanhost $target $chan] 3]"
		} else {
			set banmask "[maskhost ${target}![getchanhost $target $chan] $::cban::banType]"
		}
		
		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" $::cban::banDuration
		putserv "PRIVMSG $nick :Added $banmask to $chan ban list."
		return 0
	}
	
	# addban
	proc addban:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		set banmask "[lindex [split $text] 1]"
		
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: addban <#chan> <banmask>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not on $chan or $chan is set as inactive."
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $nick :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {$banmask eq ""} {
			putserv "PRIVMSG $nick :ERROR! Syntax: addban <#chan> <banmask>"
			return 0
		}
		
		if {$banmask eq "*!*@*"} {
			putserv "PRIVMSG $nick :ERROR! That mask is too broad and therefore is denied"
			return 0
		}
		
		if {[matchstr $banmask $::botname]} {
			putkick $chan $nick [format $::cban::revengeBan $nick]
			return 0
		}
		
		pushmode $chan +b $banmask
		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" 0
		putserv "PRIVMSG $nick :Added $banmask to $chan ban list."
		return 0
	}
	
	# kick
	proc kick:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		set target "[lindex [split $text] 1]"
		
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: kick <#chan> <nick>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not on $chan or $chan is set as inactive."
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $nick :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {$target eq ""} {
			putserv "PRIVMSG $nick :ERROR! Syntax: kick <#chan> <nick>"
			return 0
		}
		
		if {[isbotnick $target]} {
			putkick $chan $nick [format $::cban::revengeKick $nick]
			return 0
		}
		
		putkick $chan $target $::cban::kickReason
		return 0
	}
	
	# uncban
	proc uncban:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		variable unbanmask "[lindex [split $text] 1]"
		
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: uncban <#chan> <banmask>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not or $chan or $chan is set as inactive."
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {![botisop $chan]} {
			putserv "PRIVMSG $nick :ERROR! I'm not OP on $chan"
			return 0
		}
		
		if {$unbanmask eq ""} {
			putserv "PRIVMSG $nick :ERROR! Syntax: uncban <unbanmask>. Type: bans <#chan> to see the ban list."
			return 0
		}
		
		if {![isban $unbanmask $chan]} {
			putserv "PRIVMSG $nick :ERROR! $unbanmask doesn't exist on my database."
			return 0
		}
		
		killchanban "$chan" "$unbanmask"
		pushmode $chan -b $unbanmask
		putserv "PRIVMSG $nick :Removed $unbanmask from $chan ban list."
		return 0
	}
	
	# bans
	proc bans:msg {nick uhost hand text} {
		set chan "[lindex [split $text] 0]"
		
		if {![matchstr "#*" $chan]} {
			putserv "PRIVMSG $nick :ERROR! Syntax: bans <#chan>"
			return 0
		}
		
		if {![botonchan $chan] || [channel get $chan inactive]} {
			putserv "PRIVMSG $nick :ERROR! I'm not on $chan or $chan is set as inactive."
			return 0
		}
		
		if {![isop $nick $chan]} {
			putserv "PRIVMSG $nick :ERROR! You need to be OP on $chan to use this command."
			return 0
		}
		
		if {[banlist $chan] eq ""} {
			putserv "PRIVMSG $nick :ERROR! There are no bans on $chan"
			return 0
		}
		
		foreach botban [banlist $chan] {
			set banmask "[lindex [split $botban] 0]"
			set creator "[lindex [split $botban] end]"
			putserv "PRIVMSG $nick :\002BanMask:\002 $banmask - \002Added by:\002 $creator"
		}
		return 0
	}		
			
	putlog "-= CBan v2.5 Loaded =-"
};
