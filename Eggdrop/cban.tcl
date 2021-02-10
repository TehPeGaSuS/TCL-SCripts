##########
# KickBan TCL
##########
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
# -=v2.2=-
# - Removed unused vars
# - Code cleanup
# - Syntax fixing
#
# -=v2.3=-
# - Added the possibility to remotely add/remove/check bans
##########

##########
# COMMANDS
##########
# - NOTE: the #chan variable is always optional and if not specified defaults to the channel
# - where the command is being issued
#
# - cban [#chan] <nick> - bans the nick in the format *!*user@host (nick needs to be in the channel)
#
# - uncban [#chan] <mask> - Removes the specified mask
#
# - bans [#chan] - Sends a PM to the user showing the current internal ban list for the channel
#
# - addban [#chan] <mask> - Adds the specified mask to the bot ban list (this doesn't do any sanity checks, so you can end up banning everyone)
#
# - tban [#chan] <nick> - Adds a temporary ban in the specified nick (nick must be on channel) with the duration
#   specified on banDuration variable
##########
# END OF COMMANDS
##########
namespace eval cban {

	##########
	# CONFIGURATION
	##########
	# Trigger for the command
	variable banstriga "!"

	# Default ban reason
	variable banReason "User has has been banned from the channel!"

	# How many minutes for the temp ban
	variable banDuration "2"
	
	# Revenge kick when someone tries to ban the bot (%nick% will be replaced by the nick of
	# the person that tried to ban the bot
	variable revengeKick "\002Revenge Kick:\002 You wish %s! Next time, try to ban \002\00304yourself\003\002!" 

	##########
	# END OF CONFIGURATION
	##########

	###############
	# DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
	###############
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
	###############

	proc getBanTriga {} {
		variable ::cban::banstriga
		return $::cban::banstriga
	}

	bind pub - ${banstriga}cban ::cban::cban:pub
	bind pub - ${banstriga}uncban ::cban::uncban:pub
	bind pub - ${banstriga}addban ::cban::addban:pub
	bind pub - ${banstriga}tban ::cban::tban:pub
	bind pub - ${banstriga}bans ::cban::chan:bans

	proc cban:pub {nick uhost hand chan text} {
		global botnick
		variable revengeKick
		variable banReason
		variable tchan "[lindex [split $text] 0]"
		if {![matchstr "#*" $tchan]} {
			variable tchan "$chan"
			variable target "[lindex [split $text] 0]"
		} else {
			variable target "[lindex [split $text] 1]"
		}
		variable bantype "[channel get $tchan ban-type]"
		variable banmask "[maskhost ${target}![getchanhost $target $tchan] $bantype]"

		if {![isidentified $nick]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command"
			return 0
		}

		if {[isidentified $nick]} {
			if {![isop $nick $tchan]} {
				putserv "PRIVMSG $chan :ERROR! $nick, you need to be OP on $tchan to use this command"
				return 0
			}
		}

		if {$target eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]cban \[#chan\] <nick>"
			return 0
		}
		
		if {[matchstr $target $botnick]} {
			putlog "kicking $nick"
			putkick $chan $nick [format $revengeKick $nick]
			return 0
		}

		if {![onchan $target $tchan]} {
			putserv "PRIVMSG $chan :ERROR! $target needs to be on $tchan"
			return 0
		}

		newchanban "$tchan" "$banmask" "$nick" "$banReason" 0
		putkick $tchan $target $banReason
		pushmode $tchan +b $banmask
		putserv "PRIVMSG $chan :$banmask added to the ban list for $tchan"
	}

	proc uncban:pub {nick uhost hand chan text} {
		global botnick
		
		variable tchan "[lindex [split $text] 0]"
		
		if {![matchstr "#*" $tchan]} {
			variable tchan "$chan"
			variable unbanmask "[lindex [split $text] 0]"
		} else {
			variable unbanmask "[lindex [split $text] 1]"
		}

		if {![isidentified $nick]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
			return 0
		}

		if {[isidentified $nick]} {
			if {![isop $nick $tchan]} {
				putserv "PRIVMSG $chan :ERROR! $nick, you need to be OP on $tchan to use this command."
				return 0
			}
		}

		if {$unbanmask eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]uncban \[#chan\] <mask>. Use [::cban::getBanTriga]bans \[#chan\]to see the channel ban list."
			return 0
		}

		if {![isban $unbanmask $tchan]} {
			putserv "PRIVMSG $chan :ERROR! $unbanmask does not exist in my database or was been removed"
			return 0
		}

		killchanban "$tchan" "$unbanmask"
		pushmode $tchan -b $unbanmask
		putserv "PRIVMSG $chan :$unbanmask removed from the ban list for $tchan"
	}

	proc addban:pub {nick uhost hand chan text} {
		global botnick botname
		variable revengeKick
		variable banReason
		variable tchan "[lindex [split $text] 0]"
		
		if {![matchstr "#*" $tchan]} {
			variable tchan "$chan"
			variable banmask "[lindex [split $text] 0]"
		} else {
			variable banmask "[lindex [split $text] 1]"
		}
		
		

		if {![isidentified $nick]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
			return 0
		}

		if {[isidentified $nick]} {
			if {![isop $nick $tchan]} {
				putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP to use this command"
				return 0
			}
		}

		if {$banmask eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]addban \[#chan\] <mask>"
			return 0
		}

		if {[matchstr $banmask "*!*@*"]} {
			putserv "PRIVMSG $chan :ERROR! That mask is too broad and therefore is denied"
			return 0
		}
		
		if {[matchstr $banmask $botname]} {
			putlog "kicking $nick"
			putkick $chan $nick [format $revengeKick $nick]
			return 0
		}
		
		newchanban "$tchan" "$banmask" "$nick" "$banReason" 0
		pushmode $tchan +b $banmask
		putserv "PRIVMSG $chan :$banmask added to the ban list for $tchan"
	}

	proc tban:pub {nick uhost hand chan text} {
		global botnick
		variable revengeKick
		variable tchan "[lindex [split $text] 0]"
		if {![matchstr "#*" $tchan]} {
			variable tchan "$chan"
			variable target "[lindex [split $text] 0]"
		} else {
			variable target "[lindex [split $text] 1]"
		}
		variable bantype "[channel get $chan ban-type]"
		variable banmask "[maskhost ${target}![getchanhost $target $tchan] $bantype]"

		if {![isidentified $nick]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command"
			return 0
		}

		if {[isidentified $nick]} {
			if {![isop $nick $tchan]} {
				putserv "PRIVMSG $chan :ERROR! $nick, you need to be OP on $tchan to use this command"
				return 0
			}
		}

		if {$target eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]tban \[#chan\] <nick>"
			return 0
		}
		
		if {[matchstr $target $botnick]} {
			putlog "kicking $nick"
			putkick $chan $nick [format $revengeKick $nick]
			return 0
		}

		if {![onchan $target $tchan]} {
			putserv "PRIVMSG $chan :ERROR! $target needs to be on $tchan"
			return 0
		}

		newchanban "$tchan" "$banmask" "$nick" "$banReason" $::cban::banDuration
		putkick $tchan $target $banReason
		pushmode $tchan +b $banmask
		putserv "PRIVMSG $chan :$banmask temprorarily banned on $tchan"
	}


	proc chan:bans {nick uhost hand chan text} {
		global botnick
		
		variable tchan [lindex [split $text] 0]
		
		if {![matchstr "#*" $tchan]} {
			variable tchan "$chan"
		}

		if {![isidentified $nick]} {
			putserv "PRIVMSG $chan :ERROR! $nick, you need to be identified to use this command."
			return 0
		}

		if {[isidentified $nick]} {
			if {![isop $nick $tchan]} {
				putserv "PRIVMSG $chan :ERROR! $nick, you need to have at least OP on $tchan to use this command."
				return 0
			}
		}
		
		if {[banlist $tchan] eq ""} {
			putserv "PRIVMSG $chan :There are no bans on $tchan"
			return 0
		}

		putquick "PRIVMSG $chan :BANLIST for $tchan sent to $nick"

		foreach botban [banlist $tchan] {
			variable banmask [lindex [split $botban] 0]
			variable creator [lindex [split $botban] end]
			putserv "PRIVMSG $nick :\002BanMask:\002 $banmask - \002Creator:\002 $creator"
		}
		return 0
	}

	putlog "CBan v2.3 @ 10/02/2021 - Loaded"
};
