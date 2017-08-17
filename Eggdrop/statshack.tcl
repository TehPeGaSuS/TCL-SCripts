#################
# StatsMod Hack #
#################
# This script is a way to provide tracking stats by nickname, while that function isn't on the module itself.
# I've done it to personal use, so don't expect it to be a super script! :D
# It's advisable to edit it to fit your needs
# In order to use this script you have to do a few changes on your stats.conf. They're the following:
## set autoadd 0
## set use-eggdrop-userfile 1
## set anti-autoadd-flags "mnofvb-|mnofvb-"
## set anti-stats-flag "b|b"
# Enjoy!

# Badnick list
# Set here the nicks/pattern that you don't want to be added to StatsMod (good to exclude bots and those webchat nicknames)
set badnicks {"*mibbit*" "*webchat*" "botnick"}

# Adding users to the userfile
bind cron - "*/5 * * * *" addstats

# Changing user host to user!*@*
bind cron - "*/6 * * * *" chghost

# Adding new nicks upon nick change to userfile
bind nick - "*" addnew

# Purging badnicks (perhaps we added/removed new badnicks)
bind cron - "0 * * * *" purgestats

# Proc off adding nicks
proc addstats {minute hour day month wweekday} {
	global badnicks
	foreach chan [channels] {
		foreach user [chanlist $chan] {
			if {![validuser $user]} {
				foreach bad [split $badnicks] {
					if {![string match -nocase "$bad" $user]} {
						adduser $user ${user}!*@*
						putlog "Added $user to StatsMod"
					}
				}
			}
		}
	}
}

# Proc off changing hosts
proc chghost {minute hour day month wweekday} {
	foreach user [userlist] {
		set h [getuser $user HOSTS]
		if {$h eq "${user}!*@*"} {
			return 0
		} else {
			setuser $user HOSTS
			setuser $user HOSTS "${user}!*@*"
			putlog "Changed HOSTS of $user to ${user}!*@*"
		}
	}
}

# Proc off adding new nicks
proc addnew {nick uhost hand chan newnick} {
	global badnicks
	if {![validuser $newnick]} {
		foreach bad [split $badnicks] {
			if {![string match -nocase "$bad" $newnick]} {
				adduser $newnick ${newnick}!*@*
				putlog "Added $newnick to StatsMod"
			}
		}
	}
}

# Proc of purging stats
proc purgestats {minute hour day month weekday} {
	global badnicks
	foreach user [userlist] {
		foreach bad [split $badnicks] {
			if {![string match -nocase "$bad" $user]} {
				deluser $user
			}
		}
	}
}
