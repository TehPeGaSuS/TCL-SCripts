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
# 		set anti-autoadd-flags "-|-"
#		set anti-stats-flag "b|k"
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

# List of nicks that we don't want on the stats
# One per line, enclosed within quotes and lowercase
set badnicks {
	"chanserv"
	"nickserv"
}

# We also don't want service bots to be counted
# Put here your services server address
set services "*!*@services.domain.tld"


##########
# End of configuration
##########

bind cron - "*/$checktime * * * *" check
bind cron - "*/$hfixtime * * * *" hfix
bind nick - "*" checknick



proc check {minute hour day month weekday} {
	global botnick botname badnicks services
	
	foreach chan [channels] {
		foreach nick [chanlist $chan] {
			if {![validuser $nick]} {
				set uhost "*![getchanhost $nick $chan]"
				if {!([matchstr $botnick $nick] || [strlwr $nick] in $badnicks || [matchstr $services $uhost] || [matchstr $botname $uhost])} {
					adduser $nick ${nick}!*@*
				}
			}
		}
	}
	return 0
}

proc checknick {nick uhost hand chan newnick} {
	global botnick botname badnicks services
	
	set uhost "*![getchanhost $newnick $chan]"
	
	if {![validuser $newnick]} {
		if {!([matchstr $botnick $newnick] || [strlwr $newnick] in $badnicks || [matchstr $services $uhost] || [matchstr $botname $uhost])} {
			adduser $newnick ${newnick}!*@*
		}
	}
	return 0
}

proc hfix {minute hour day month weekday} {
	global botnick botname
	foreach user [userlist] {
		if {![matchattr [nick2hand $user] mno]} {
			setuser $user HOSTS
			setuser $user HOSTS "${user}!*@*"
		}
	}
	return 0
}

putlog "-= StatsMod Hack v1.1 loaded =-"
