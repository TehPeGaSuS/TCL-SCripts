#-----------------------#
# Channel Security Code #
#-----------------------#

#----------------------------------------------------------------------------------#
# Q: What it does?                                                                 #
# A: With this script, you can set your channel to +m and the bot will give        #
#    voice to the user that sends the correct verification code via private        #
#    to the bot. The idea is to allow true users to talk while preventing spammers #
#    from doing any damage to your channel.                                        #
#----------------------------------------------------------------------------------#

#---------------------------------------------------------------------------------#
# NOTE: This script will automatically give the "A" user flag for each user       #
#       that is added to the bot. It will skip users that are in the verification #
#       phase and will not add them.                                              #
#---------------------------------------------------------------------------------#

namespace eval chansec {
	#---------------#
	# Configuration #
	#---------------#
	# The channel to enable this script in
	variable jailChan "#thelounge"

	# How many seconds to wait before executing the script?
	# Minimum of 5s is advisable
	variable jailTimer "5"

	#----------------------#
	# End of configuration #
	#----------------------#

	#--------------------------------------------------------------------------------------------------------------#
	#                        DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING                         #
	#                                                                                                              #
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. #
	#--------------------------------------------------------------------------------------------------------------#

	# This gives the "A" flag to users added to the bot, such as owners, masters, global ops, etc
	# Users on the verification phase will be skipped and not added
	bind cron * "*/5 * * * *" ::chansec::autoflag

	proc autoflag {minute hour day month weekday} {
		foreach nick [userlist] {
			if {[matchattr [nick2hand $nick] -ZA]} {
				chattr $nick +A
			}
		}
	}

	# Let's handle the user join, so we can create the code
	bind join * "$::chansec::jailChan *" ::chansec::jail_join

	proc jail_join {nick uhost hand chan} {

		if {(![string match "*m*" [getchanmode $chan]] || [isbotnick $nick])} {
			return 0
		}

		utimer $::chansec::jailTimer [list ::chansec::jail_check "$nick" "$uhost" "$hand" "$chan"]
	}

	proc jail_check {nick uhost hand chan}  {

		if {([validuser [nick2hand $nick]] || [isop $nick $chan] || [ishalfop $nick $chan] || [isvoice $nick $chan])} {
			return 0
		}

		set jailPass "[randstring 16 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]"

		if {![validuser [nick2hand $nick]]} {
			adduser $nick ${nick}!*@*
			chattr $nick +Z
			setuser $nick PASS $jailPass
			setuser $nick COMMENT $jailPass
		}

		putserv "PRIVMSG $chan :Hello ${nick}! I'll send you a PVT message with instructions on how to get +v on ${chan}."
		putserv "PRIVMSG $chan :If you have your PVT locked, you can re-request the message with \"/msg $::botnick resend\""

		utimer 5 [list {
			puthelp "PRIVMSG $nick :Your verification code is: $jailPass"
			puthelp "PRIVMSG $nick :Type \"verify $jailPass\" to verify yourself."
		}]
	}

	# User verification
	bind msg * verify ::chansec::jail_verify

	proc jail_verify {nick uhost hand text} {

		set jailCode [lindex [split $text] 0]

		if {![validuser [nick2hand $nick]]} {
			putserv "PRIVMSG $nick :Sorry ${nick}, but you haven't been processed yet."
			return
		}

		if {[passwdok [nick2hand $nick] $jailCode] && [matchattr [nick2hand $nick] +Z-A]} {
			putserv "PRIVMSG $nick :${nick}, you've been successfully verified."
			putserv "MODE $::chansec::jailChan +v $nick"
			deluser $nick
		} else {
			putserv "PRIVMSG $nick :!ERROR! Incorrect verification code. Please try again."
			return
		}
	}

	# Resend the code
	bind msg * resend ::chansec::resend_code

    proc resend_code {nick uhost hand text} {

		if {![matchattr [nick2hand $nick] Z]} {
			putserv "PRIVMSG $nick :You have been verified already. Please rejoin the channel if this is an error."
			return 0
		}

		set jailCode [getuser [nick2hand $nick] COMMENT]

		putserv "PRIVMSG $nick :Your verification code is: $jailCode"
		putserv "PRIVMSG $nick :Type \"verify $jailCode\" to verify yourself."
		return
	}

    # Exception handling such as part and quit, to remove the user
	bind part * "$::chansec::jailChan *" ::chansec::jail_remove
	bind sign * "$::chansec::jailChan *" ::chansec::jail_remove

	proc jail_remove {nick uhost hand chan reason} {

		if {[validuser $nick] && [matchattr [nick2hand $nick] +Z-A]} {
			deluser $nick
			return
		}
	}

	# Lets handle if someone gives +q/+a/+o/+h/+v to the user while they
	# are in the verification phase
	bind mode * "$::chansec::jailChan +*" ::chansec::jail_mode

	proc jail_mode {nick uhost hand chan mode target} {
		if {$target eq "" || [isbotnick $target] || ![onchan $target $chan]} {
			return 0
		}

		if {[matchattr [nick2hand $target] +Z-A]} {
			deluser $target
			return
		}
	}

	putlog "-= Channel Security Code v1.5 by PeGaSuS loaded (02/09/2024-16:55) =-"
}; #end of chansec namespace
