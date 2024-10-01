# --------------------------------------------------------------------------#
# This script is to be used with an eggdrop connected to a ZNC.             #
# The bot must have admin rights to be able to create and delete clones     #
# this script was created with the goal of helping network admins testing   #
# their flood protections and other things. DO NOT use it to flood networks #
# or you may face a permanent ban                                           #
#                                                                           #
# Last revision: 01/10/2024 - 22:13                                         #
#---------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------#
### Current commands:                                                                ###
#                                                                                      #
# clonex - Check if the bot is connected                                               #
# genclones <number of clones> - Creates the specified amount of clones                #
# delclone <nick> - Deletes a specific clone user                                      #
# delallclones - Delete all clones                                                     #
# addchannel <#channel> - Adds the specified channel to the clones channel list        #
# delchannel <#channel> - Deletes the specified channel from the clones channel list   #
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
	# If empty, ZNC will try to pick any #
	# IP from the box (usually the 1st   #
	# assigned IPv4 or IPv6              #
 	#------------------------------------#
	variable bindhost ""

 	#-------------------------#
	# Password for the clones #
 	#-------------------------#
	variable passwd "VeenuLeophah0peiha0ib0ae"

 	#------------------------------------------#
	# How long should the clones nicknames be? #
 	#------------------------------------------#
	variable nclength "16"

 	#--------------#
	# Network name #
 	#--------------#
	variable netname "DALnet"

 	#-------------#
	# IRC address #
 	#-------------#
	variable irchost "irc.dal.net"

 	#-------------------------------------------------------------#
	# IRC port (with "+" before the port number if using SSL/TLS) #
 	#-------------------------------------------------------------#
	variable ircport "+6697"

 	#--------------------------------#
	# Channel for the clones to join #
 	#--------------------------------#
	variable chanclone "#CloneX"

	#-----------------------------------#
	# Store messages on the clones ZNC? #
	# 0 = no, 1 = yes                   #
	#-----------------------------------#
	variable storemsg "0"
	
	#-------#
	# BINDS #
	#-------#

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
	bind pub - ${::genclones::cloneTrigger}addchannel ::genclones::addchan_clones

 	#----------------------------------------#
	# Let's remove a channel from the clones #
 	#----------------------------------------#
	bind pub - ${::genclones::cloneTrigger}delchannel ::genclones::delchan_clones

    #------------------------------#
    # Delete a specific clone user #
    #------------------------------#
    bind pub - ${::genclones::cloneTrigger}delclone ::genclones::del_clone

 	#----------------------------#
	# Lets delete ALL the clones #
 	#----------------------------#
	bind pub - ${::genclones::cloneTrigger}delallclones ::genclones::delall_clones

	########################
	# End of configuration #
	########################
	
	#--------------------------------------------------------------------------------------------------------------#
	#                        DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING                         #
	#                                                                                                              #
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. #
	#--------------------------------------------------------------------------------------------------------------#
	
	#-------#
	# PROCS #
	#-------#
	proc status_check {nick uhost hand chan text} {
		putnow "PRIVMSG $chan :Online!"
		return 0
	}
	
	###
	proc gen_clones {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return
		}
		
		variable clonenum "[lindex [split $text] 0]"
		
		if {$clonenum eq ""} {
			putnow "PRIVMSG $chan :ERROR! Syntax: ${::genclones::cloneTrigger}genclone <number of clones>"
			return
		}
		
		set i 0
		putnow "PRIVMSG $chan :Starting generation of $clonenum clones."
		while {$i < $clonenum} {
			incr i
			::genclones::create_user $nick $uhost $hand $chan $text
		}
	}
	
	###
	proc create_user {nick uhost hand chan text} {
		
		variable target "KS-[randstring $::genclones::nclength abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return
		}

		adduser $target ${target}!*@*
		chattr $target +X
		putnow "PRIVMSG *controlpanel :AddUser $target $::genclones::passwd"
		putnow "PRIVMSG *controlpanel :AddNetwork $target $::genclones::netname"
		if {$::genclones::bindhost ne ""} {
			putnow "PRIVMSG *controlpanel :Set BindHost $target $::genclones::bindhost"
		}
		putnow "PRIVMSG *controlpanel :AddChan $target $::genclones::netname $::genclones::chanclone"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname keepnick"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname kickrejoin"
		putnow "PRIVMSG *controlpanel :LoadNetModule $target $::genclones::netname simple_away"
		if {$::genclones::storemsg == "0"} {
			putnow "PRIVMSG *controlpanel :Set ChanBufferSize $target 0"
			putnow "PRIVMSG *controlpanel :Set QueryBufferSize $target 0"
		}
		putnow "PRIVMSG *controlpanel :AddServer $target $::genclones::netname $::genclones::irchost $::genclones::ircport"
		putnow "PRIVMSG *status :saveconfig"
		return
	}
	
	###
	proc addchan_clones {nick uhost hand chan text} {
		
		variable tchan "[lindex [split $text] 0]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return
		}
		
		if {![matchstr "#*" $tchan]} {
			putnow "PRIVMSG $chan :ERROR! Syntax: ${::genclones::cloneTrigger}addchan <#channel name>"
			return
		}
		
		foreach clone [split [userlist]] {
			if {[matchattr [nick2hand $clone] +X]} {
				putnow "PRIVMSG *controlpanel :AddChan $clone $::genclones::netname $::genclones::chanclone"
			}
		}
		return
	}
	
	###
	proc delchan_clones {nick uhost hand chan text} {
		
		variable tchan "[lindex [split $text] 0]"
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		if {![matchstr "#*" $tchan]} {
			putnow "PRIVMSG $chan :ERROR! Syntax: ${::genclones::cloneTrigger}delchan <#channel name>"
			return 0
		}
		
		foreach clone [split [userlist]] {
			if {[matchattr [nick2hand $clone] +X]} {
				putnow "PRIVMSG *controlpanel :DelChan $clone $::genclones::netname $::genclones::chanclone"
			}
		}
	}

	###
	proc del_clone {nick uhost hand chan text} {
		set target [lindex [split $text] 0]

		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return
		}

		if {$target eq ""} {
			putnow "PRIVMSG $chan :ERROR! Syntax: ${::genclones::cloneTrigger}delclone <nick>"
			return
		}

		putnow "PRIVMSG $chan :Deleting clone ${target}..."

		if {[matchattr [nick2hand $target] +X]} {
			deluser $target
			putnow "PRIVMSG *controlpanel :DelUser $target"
			return
		} else {
			putnow "PRIVMSG $chan :$target is not a clone"
			return
		}
	}
		
	###
	proc delall_clones {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		putnow "PRIVMSG $chan :Deleting all clones..."

		foreach clone [split [userlist]] {
			if {[matchattr [nick2hand $clone] +X]} {
				deluser $clone
				putnow "PRIVMSG *controlpanel :DelUser $clone"
			}
		}
		return
	}
	
	################
	# END OF PROCS #
	################
	
	putlog "::: CloneX TCL Loaded :::"
};
