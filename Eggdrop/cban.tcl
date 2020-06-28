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
# 20/06/2020 - v1
# - Initial release
##########
# 28/06/2020 - v2
# - Converted the script into a namespace
# - Added temporary ban command, default ban reason and ban duration (for temp ban)
##########

##########
# COMMANDS
##########
# - cban <nick> - bans the nick in the format *!*user@host (nick needs to be in the channel)
#
# - uncban <mask|last> - Removes the specified mask or the last ban if 'last' is specified instead a mask
#
# - bans - Sends a PM to the user showing the current internal ban list for the channel
#
# - addban <mask> - Adds the specified mask to the bot ban list (this doesn't do any sanity checks, so you can end up banning everyone)
#
# - tban <nick> - Adds a temporary ban in the specified nick (nick must be on channel) with the duration
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
		variable botnick lastBan banReason

		variable target "[lindex [split $text] 0]"
		variable banmask "[maskhost [getchanhost $target $chan] 1]"

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
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]cban <nick> <duration"
			return 0
		}

		if {![onchan $target $chan]} {
			putserv "PRIVMSG $chan :ERROR! $target needs to be in the channel."
			return 0
		}

		variable lastBan "$banmask"

		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" 0
		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		putserv "PRIVMSG $chan :$banmask added to the ban list for $chan"
	}

	proc uncban:pub {nick uhost hand chan text} {
		variable botnick lastBan banReason

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
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]uncban \[mask|last\ (removes last ban)]. Use [::cban::getBanTriga]bans to see the channel ban list."
			return 0
		}

		if {$unbanmask eq "last"} {
			killchanban "$chan" "$::cban::lastBan"
			pushmode $chan -b $::cban::lastBan
			putserv "PRIVMSG $chan :$::cban::lastBan removed from the ban list for $chan"
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
		variable botnick lastBan banReason

		variable banmask [lindex [split $text] 0]

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
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]addban <mask>"
			return 0
		}

		if {[matchstr $banmask "*!*@*"]} {
			putserv "PRIVMSG $chan :ERROR! That mask is too broad and therefore is denied"
			return 0
		}

		variable lastBan "$banmask"
		newchanban "$chan" "$banmask" "$nick" "$::cban::banreason" 0
		pushmode $chan +b $banmask
		putserv "PRIVMSG $chan :$banmask added to the ban list for $chan"
	}

	proc tban:pub {nick uhost hand chan text} {
		variable botnick banDuration banReason lastBan

		variable target "[lindex [split $text] 0]"

		variable banmask "[maskhost [getchanhost $target $chan] 1]"

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
			putserv "PRIVMSG $chan :ERROR! Syntax: [::cban::getBanTriga]cban <nick> <duration"
			return 0
		}

		if {![onchan $target $chan]} {
			putserv "PRIVMSG $chan :ERROR! $target needs to be in the channel."
			return 0
		}

		variable lastBan "$banmask"

		newchanban "$chan" "$banmask" "$nick" "$::cban::banReason" $::cban::banDuration
		putkick $chan $target $::cban::banReason
		pushmode $chan +b $banmask
		putserv "PRIVMSG $chan :$banmask added to the ban list for $chan"
	}


	proc chan:bans {nick uhost hand chan text} {
		variable botnick

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
			variable banmask [lindex [split $botban] 0]
			variable creator [lindex [split $botban] end]
			putserv "PRIVMSG $nick :\002BanMask:\002 $banmask - \002Creator:\002 $creator"
		}
		return 0
	}

	putlog "CBan v2 @ 28/06/2020 - Loaded"
};