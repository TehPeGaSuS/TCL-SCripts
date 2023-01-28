# This script is to be used with an eggdrop connected to a ZNC.
# The bot must have admin rights to be able to create and delete clones
# this script was created with the goal of helping network admins testing their flood protections
# and other things. DO NOT use it to flood networks or you may face a permanent ban

namespace eval genclones {
	
	#################
	# CONFIGURATION #
	#################
	
	# IP that will be used by the clones
	variable bindhost "2001:4860:4860::8888"
	
	# Password for the clones (can be anything)
	variable passwd "VeenuLeophah0peiha0ib0ae"
	
	# Network name
	variable netname "example"
	
	# IRC hostname
	variable irchost "irc.example.org"
	
	# IRC port (with + before the port number if using SSL/TLS)
	variable ircport "+6697"
	
	# Trigger to use with the commands
	variable zncTrigger "!"
	
	# Flag to protect users from being deleted (default to f)
	# Don't forget to `.chattr <user> +f` via partyline to prevent them from being deleted
	variable protected "f"
	
	#########
	# BINDS #
	#########
	
	# Lets check if the bot is connected
	bind pub - ${::genclones::zncTrigger}clonex ::genclones::status_check
	
	# Lets generate X number of clones at once
	bind pub - ${::genclones::zncTrigger}genclones ::genclones::gen_clone
	
	# Lets generate just one clone
	bind pub - ${::genclones::zncTrigger}addclone ::genclones::create_user
	
	#Lets delete ALL the clones
	bind pub - ${::genclones::zncTrigger}delclones ::genclones::del_clones
	
	########################
	# END OF CONFIGURATION #
	################################################################################################################
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. #
	################################################################################################################
	
	# This is how we generate a random nickname with uppercase,
	# lowercase letters and 12 characters long
	variable target "[randstring 12 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]"
	
	# This is how we get the tigger to be used on messages and inside procs
	proc getZncTrigger {} {
		variable ::genclones::zncTrigger
		return $::genclones::zncTrigger
	}
	
	#########
	# PROCS #
	#########
	proc status_check {nick uhost hand chan text} {
		putnow "PRIVMSG $chan :Online!"
		return 0
	}
	
	###
	proc gen_clone {nick uhost hand chan text} {
		
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
			after 5000 [list [create_user $nick $uhost $hand $chan $text]]
		}
		putnow "PRIVMSG $chan :Generated $i clones."
		return 0
	}
	
	###
	proc create_user {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		if {[validuser $::genclones::target]} {
			return 0
		}

		adduser $::genclones::target ${::genclones::target}!*@*
		putnow "PRIVMSG *controlpanel :AddUser $::genclones::target $::genclones::passswd"
		putnow "PRIVMSG *controlpanel :AddNetwork $::genclones::target $::genclones::netname"
		putnow "PRIVMSG *controlpanel :Set BindHost $::genclones::target $::genclones::bindhost"
		putnow "PRIVMSG *controlpanel :AddChan $::genclones::target $::genclones::netname #CloneX"
		putnow "PRIVMSG *controlpanel :LoadNetModule $::genclones::target $::genclones::netname keepnick"
		putnow "PRIVMSG *controlpanel :LoadNetModule $::genclones::target $::genclones::netname kickrejoin"
		putnow "PRIVMSG *controlpanel :LoadNetModule $::genclones::target $::genclones::netname route_replies"
		putnow "PRIVMSG *controlpanel :LoadNetModule $::genclones::target $::genclones::netname simple_away"
		putnow "PRIVMSG *controlpanel :AddServer $::genclones::target $::genclones::netname $::genclones::irchost $::genclones::ircport"
		return 0
	}
	
	###
	proc del_clones {nick uhost hand chan text} {
		
		if {![matchattr $hand n]} {
			putnow "PRIVMSG $chan :ERROR! You don't have access, ${nick}."
			return 0
		}
		
		foreach clone [split [userlist]] {
			if {![matchattr $clone $::genclones::protected]} {
				deluser $clone
				putnow "PRIVMSG *controlpanel :DelUser $clone"
			}
		}
		return 0
	}
	
	################
	# END OF PROCS #
	################
	
	putlog "::: CloneX TCL v1.0 loaded :::"
};