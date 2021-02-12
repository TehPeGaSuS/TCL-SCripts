##########
# Random Liner Graber
##########
# This script reads a random line from a file
# and displays it on the channel when triggered
# by the public command specified
# Enjoy!
##########

##########
# CONFIGURATION
##########
#
##########
# Trigger
##########
set readTrigger "!"

##########
# File location (full path is preferred)
##########
set fname "/home/eggdrop/kickban/scripts/randoms.txt"

##########
# End of configuration
##########
# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. (THANKS thommey)
##########

##########
# Binds
##########
bind pub - ${readTrigger}url url:pub

##########
# Procs
##########
proc url:pub {nick uhost habd chan text} {
	global fname
	
	if {![file exists $fname]} {
		putserv "PRIVMSG $chan :There's no file to be read"
		return 0
	}
	
	set fp [open $fname "r"]
	set data [read -nonewline $fp]
	close $fp
	set lines [split $data "\n"]
	set numlines [llength $lines]
	set num [rand $numlines]
	set randline [lindex $lines $num] 
	putserv "PRIVMSG $chan :$randline"
	return 0
}
