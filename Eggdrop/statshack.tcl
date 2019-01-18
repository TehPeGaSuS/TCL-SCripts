######################################
# THIS IS A WIP! ERRORS ARE EXPECTED #
######################################

#################
# StatsMod Hack #
#################
#
# This script is a way to provide tracking stats by nickname, while that function isn't on the module itself.
# I've done it to personal use, so don't expect it to be a super script! :D
# It's advisable to edit it to fit your needs
# In order to use this script you have to do a few changes on your stats.conf. They're the following:
## set autoadd 0
## set use-eggdrop-userfile 1
## set anti-autoadd-flags "mnofvb-|mnofvb-"
## set anti-stats-flag "b|b"
# Enjoy!

### Configuration ###
# How many minutes between each add user check?
set checktime "5"

### End of configuration ###

### Binds ###
# Adding users to the userfile
bind cron - "*/$checktime * * * *" addstats

# Adding new nicks upon nick change to userfile
bind nick - "*" addnew
### End of Binds ###

### Procedures ###
# Proc off adding nicks
proc addstats {minute hour day month weekday} {
	foreach chan [channels] {
		foreach user [chanlist $chan] {
			if {![validuser $user]} {
				# If user is a Guest, don't add it
				if {[string match "Guest*" $user]} {
					return
				} else {
				# User doesn't exist. Lets add them to eggdrop userfile
				adduser $user ${user}!*@*
			}
		}
	}
}

# Proc off adding new nicks
proc addnew {nick uhost hand chan newnick} {
	if {![validuser $newnick]} {
		adduser $newnick ${newnick}!*@*
	}
}
### End of procedures ###

putlog "StatsMod Tracking System Hack loaded"
