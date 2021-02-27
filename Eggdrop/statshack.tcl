##########
# StatsMod Hack
##########
# THIS SCRIPT IS EXPERIMENTAL AND CAN MAKE YOUR EGGDROP'S USER FILE TO GROW HUGELY AND CAUSE BOT LAG!
# USE AT YOUR OWN RISK! YOU HAVE BEEN WARNED!!!
##########
#
# This script is a way to provide tracking stats by nickname, while that function isn't on the module itself.
# I've done it to personal use, so don't expect it to be a super script! :P
# It's advisable to edit it to fit your needs
# In order to use this script you have to do a few changes on your stats.conf. They're the following:
#
#		set autoadd -1
#		set use-eggdrop-userfile 1
# 		set anti-autoadd-flags "mnofvb-|mnofvb-"
#		set anti-stats-flag "b|b"
#
# Be sure that you edit your stats.conf this way before starting the bot.
#
# Enjoy!
##########

##########
# Configuration
##########
# How many minutes between check?
##########
# For each user in each channel to add them if they don't exist yet
set checktime "2"

# For each user on the user file to "fix" their hosts
set hfixtime "5"

##########
# End of configuration
##########

bind cron - "*/$checktime * * * *" check
bind cron - "*/$hfixtime * * * *" hfix
bind nick - "*" checknick

set badnicks {
	"chanserv"
	"nickserv"
}

set services "*!*@services.domain.tld"

proc check {minute hour day month weekday} {
	global botnick botname badnicks services
	
	foreach chan [channels] {
		foreach nick [chanlist $chan] {
			if {![validuser $nick]} {
				set uhost [maskhost ${nick}![getchanhost $nick $chan] 0]
				if {!([matchstr $nick $botnick] || [strlwr $nick] in $badnicks || [matchstr $uhost $services] || [matchstr $uhost $botname])} {
					adduser $nick ${nick}!*@*
				}
			}
		}
	}
	return 0
}

proc checknick {nick uhost hand chan newnick} {
	global botnick botname badnicks services
	
	set uhost [maskhost ${newnick}![getchanhost $newnick $chan] 0]
	
	if {![validuser $newnick]} {
		if {!([matchstr $newnick $botnick] || [strlwr $newnick] in $badnicks || [matchstr $uhost $services] || [matchstr $uhost $botname])} {
			adduser $newnick ${newnick}!*@*
		}
	}
	return 0
}

proc hfix {minute hour day month weekday} {
	global botnick botname
	foreach user [userlist] {
		if {![matchattr [nick2hand $user] mno]} {
			setuser $user HOSTS ""
			setuser $user HOSTS "${user}!*@*"
		}
	}
	return 0
}

putlog "-= StatsMod Hack v1.1 loaded =-"
