# --------------------------------------------------------------------------#
# This script is to be used with an eggdrop connected to a ZNC.             #
# The bot must have admin rights to be able to create and delete clones     #
# this script was created with the goal of helping network admins testing   #
# their flood protections and other things. DO NOT use it to flood networks #
# or you may face a permanent ban                                           #
#                                                                           #
# Last revision: 03/07/2024 - 23:22                                         #
#---------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------#
# Current commands:                                                                    #
# clonex - Check if the bot is connected                                               #
# genclones <number of clones> - Creates the specified amount of clones                #
# delclones - Delete all clones                                                        #
# addchan <#channel name> - Adds the specified channel to the clones channel list      #
# delchan <#channel name> - Deletes the specified channel from the clones channel list #
#--------------------------------------------------------------------------------------#

namespace eval genclones {
	
	#################
	# CONFIGURATION #
	#################

 	#----------------------------------#
	# Trigger to use with the commands #
 	#----------------------------------#
	variable cloneTrigger "!"

 	#------------------------------------#
	# IP that will be used by the clones #
 	#------------------------------------#
	variable bindhost "2001:4860:4860::8888"

 	#-------------------------#
	# Password for the clones #
 	#-------------------------#
	variable passwd "VeenuLeophah0peiha0ib0ae"

 	#----------------------------------------------------------------#
	# How long should the clones nicknames be?                       #
	# NOTE: nicks will be nclength+2, so if `nclength` is set to 12, #
	# nicks will be 14 chars long                                    #
 	#----------------------------------------------------------------#
	variable nclength "12"

 	#--------------#
	# Network name #
 	#--------------#
	variable netname "example"

 	#-------------#
	# IRC address #
 	#-------------#
	variable irchost "irc.example.org"

 	#-------------------------------------------------------------#
	# IRC port (with "+" before the port number if using SSL/TLS) #
 	#-------------------------------------------------------------#
	variable ircport "+6697"

 	#--------------------------------#
	# Channel for the clones to join #
 	#--------------------------------#
	variable chanclone "#CloneX"

 	#---------------------------------------------------------------------#
	# List of users that will be protected when deleting all the clones   #
	# (such as bot admins, ops, etc) when we use the command "delclones", #
	# otherwise even bot owner will be deleted and lose bot access.       #
	# This users also won't have new channels added/removed to/from them  #
	# I strongly advise to keep "-hq"                                     #
	# NOTE: One nick per line and all lowercase                           #
 	#---------------------------------------------------------------------#
	variable protected {
		"-hq"
		"admin1"
		"admin2"
	}
	
	########################
	# End of configuration #
	########################
	
	#--------------------------------------------------------------------------------------------------------------#
	#                        DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING                         #
	#                                                                                                              #
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. #
	#--------------------------------------------------------------------------------------------------------------#
	
	
	#########
	# BINDS #
	#########

 	#------------------------------------#
	# Lets check if the bot is connected #
 	#------------------------------------#
	bind pub - ${::genclones::cloneTrigger}clonex ::genclones::status_check

 	#------------------------------------------#
	# Lets generate X number of clones at once #
 	#------------------------------------------#
	bind pub - ${::genclones::cloneTrigger}genclones ::genclones::gen_clones

 	#-----------------------------------------------#
	# Lets add a new channel for the clones to join #
 	#-----------------------------------------------#
	bind pub - ${::genclones::cloneTrigger}addchan ::genclones::addchan_clones

 	#----------------------------------------#
	# Let's remove a channel from the clones #
 	#----------------------------------------#
	bind pub - ${::genclones::cloneTrigger}delchan ::genclones::delchan_clones

 	#----------------------------#
	# Lets delete ALL the clones #
 	#----------------------------#
	bind pub - ${::genclones::cloneTrigger}delclones ::genclones::del_clones
	
	#-----------------------------------------------------------------------#
 	# This is how we get the tigger to be used on messages and inside procs #
  	#-----------------------------------------------------------------------#
	proc getZncTrigger {} {
		variable ::genclones::cloneTrigger
		return $::genclones::cloneTrigger
	}
	
	#########
	# PROCS #
	#########
	proc status_check {nick uhost hand chan text} {
		putnow "PRIVMSG $chan :Online!"
		return 0
	}
	
	###
	proc gen_clones {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		variable clonenum "[lindex [split $text] 0]"
		
		if {$clonenum eq ""} {
			putnow "PRIVMSG $chan :ERROR! Syntax: [::genclones::getZncTrigger]genclone <number of clones>"
			return 0
		}
		
		set i 0
		putnow "PRIVMSG $chan :Starting generation of $clonenum clones."
		while {$i < $clonenum} {
			incr i
			::genclones::create_user $nick $uhost $hand $chan $text
		}
		putnow "PRIVMSG $chan :Generated $i clones."
		return 0
	}
	
	###
	proc create_user {nick uhost hand chan text} {
		
		variable target "[randstring 1 ABCDEFGHIJKLMNOPQRSTUVWXYZ]-[randstring $::genclones::nclength abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}

		adduser $target ${target}!*@*
		putnow "PRIVMSG *controlpanel :AddUser $target $::genclones::passwd"
		putnow "PRIVMSG *controlpanel :AddNetwork $target $::genclones::netname"
		putnow "PRIVMSG *controlpanel :Set BindHost $target $::genclones::bindhost"
		putnow "PRIVMSG *controlpanel :AddChan $target $::genclones::netname $::genclones::chanclone"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname keepnick"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname kickrejoin"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname route_replies"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname simple_away"
		putnow "PRIVMSG *controlpanel :Set ChanBufferSize $target 0"
		putnow "PRIVMSG *controlpanel :Set QueryBufferSize $target 0"
		putnow "PRIVMSG *controlpanel :AddServer $target $::genclones::netname $::genclones::irchost $::genclones::ircport"
		return 0
	}
	
	###
	proc addchan_clones {nick uhost hand chan text} {
		
		variable cchan "[lindex [split $text] 0]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		if {![matchstr "#*" $cchan]} {
			putnow "PRIVMSG $chan :ERROR! Syntax: [::genclones::getZncTrigger]addchan <#channel name>"
			return 0
		}
		
		foreach clone [split [userlist]] {
			if {!([strlwr $clone] in $::genclones::protected)} {
				putnow "PRIVMSG *controlpanel :AddChan $clone $::genclones::netname $::genclones::chanclone"
			}
		}
	}
	
	###
	proc delchan_clones {nick uhost hand chan text} {
		
		variable cchan "[lindex [split $text] 0]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		if {![matchstr "#*" $cchan]} {
			putnow "PRIVMSG $chan :ERROR! Syntax: [::genclones::getZncTrigger]delchan <#channel name>"
			return 0
		}
		
		foreach clone [split [userlist]] {
			if {!([strlwr $clone] in $::genclones::protected)} {
				putnow "PRIVMSG *controlpanel :DelChan $clone $::genclones::netname $::genclones::chanclone"
			}
		}
	}		
	
	###
	proc del_clones {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		foreach clone [split [userlist]] {
			if {!([strlwr $clone] in $::genclones::protected)} {
				deluser $clone
				putlog "Deleted clone: $clone"
				putnow "PRIVMSG *controlpanel :DelUser $clone"
			}
		}
		return 0
	}
	
	################
	# END OF PROCS #
	################
	
	putlog "::: CloneX TCL Loaded :::"
};
