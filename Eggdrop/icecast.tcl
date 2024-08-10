#-------------------------------------------------------------#
# Icecast script to announce musics from your online radio    #
# This should work out of the box with single source streams  #
#                                                             #
# This script was tested with eggdrop 1.9.x and Icecast 2.4.x #
#-------------------------------------------------------------#

#------------------------------------------------------------------------#
# Commands:                                                              #
# - !music - Displays the current music playing                          #
# - !np - Does the same as !music                                        #
#                                                                        #
# - !icecast <on/off> - Enables/disables the ability to see the current  #
#   music playing with the !music command                                #
#                                                                        #
# - !iceauto <on/off> - Enables/disables the automatic annoucement of    #
#   the current music playing (check is done every minute, but the music #
#   is only announced if it has changed                                  #
#------------------------------------------------------------------------#

#-----------------------------------------------------------#
#                         THANKS TO                         #
#                                                           #
# - DasBrain, for the pointers about `variable` vs `set`    #
#                                                           #
# - CrazyCat, for the help to automate de TLS detection and #
#   some other code enhancement ideas                       #
#-----------------------------------------------------------#

namespace eval icecast {

	#---------------#
	# Configuration #
	#---------------#
	# Trigger
	variable trigger "!"

	# URL for the json page
	variable jsonURL "https://your.radio.tld:8001/status-json.xsl"

	# Radio Name
	variable radioName "Your Radio Name"

	# Radio URL
	variable listenURL "https://your.radio.tld/"

	# Binds
	bind cron - "* * * * *" ::icecast::autoplaying
	bind pub - ${::icecast::trigger}music ::icecast::nowplaying
	bind pub - ${::icecast::trigger}np ::icecast::nowplaying
	bind pub - ${::icecast::trigger}icecast ::icecast::on_off
	bind pub - ${::icecast::trigger}iceauto ::icecast::auto_onoff

	#--------------------------------------------------------------------------------------------------------------#
	#                        DON'T TOUCH ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING                         #
	#                                                                                                              #
	# If you touch the code below and then complain the script "suddenly stopped working" I'll touch you at night. #
	#--------------------------------------------------------------------------------------------------------------#
	### Requirements ###
	package require http
	package require json
	
	if {[string match "https://*" $::icecast::jsonURL]} {
		if {[catch {package require tls}]} {
			putlog "ERROR: TLS package is required to use HTTPS"
			return
		} else {
			::http::register https 443 [list ::tls::socket -autoservername true]
		}
	}

	### Flags ###
	setudef flag icecast
	setudef flag iceauto

	### Last track ###
	if {![info exists ::icecast::lastTrack]} {
		set lastTrack ""
	}

	# Procs
	proc nowplaying {nick uhost hand chan text} {

		if {![channel get $chan icecast]} {
			putserv "PRIVMSG $chan :ERROR! Icecast not enabled on ${chan}."
			return 0
		}
		::icecast::announce $chan
	}

	proc autoplaying {min hour day month dow} {
		::icecast::announce all
	}

	proc announce {tchan} {
		
		set token [::http::geturl "$::icecast::jsonURL" -timeout 10000]
		set data [::http::data $token]
		set datadict [::json::json2dict $data]
		::http::cleanup $token

		if {![dict exists $datadict icestats source]} {
			if {$tchan ne "all" } {
				putserv "PRIVMSG $tchan :No source playing"
				return 0
			} else {
				return 0
			}
		}

		set dj [dict get $datadict icestats source server_name]
		set title [dict get $datadict icestats source title]
		
		if {$tchan ne "all"} {
			putserv "PRIVMSG $tchan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Tune in: $::icecast::listenURL"
			return
		} else {
			if {$::icecast::lastTrack ne "$title"} {
				set ::icecast::lastTrack "$title"
				
				foreach chan [channels] {
					if {[channel get $chan iceauto]} {
						putserv "PRIVMSG $chan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Tune in: $::icecast::listenURL"
					}
				}
			}
		}
	}

	proc on_off {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr [nick2hand $nick] m]} {
			putserv "PRIMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {$option eq "on"} {
			if {[channel get $chan icecast]} {
				putserv "PRIVMSG $chan :ERROR! Icecast already enabled on $chan"
				return 0
			} else {
				channel set $chan +icecast
				putserv "PRIVMSG $chan :Icecast enabled on $chan"
				return 0
			}
		} elseif {$option eq "off"} {
			if {![channel get $chan icecast]} {
				putserv "PRIVMSG $chan :ERROR! Icecast already disabled on $chan"
				return 0
			} else {
				channel set $chan -icecast
				putserv "PRIVMSG $chan :Icecast disabled on $chan"
				return 0
			}
		} else {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}icecast on/off"
		}
	}

	proc auto_onoff {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr [nick2hand $nick] m]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {$option eq "on"} {
			if {[channel get $chan iceauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto Icecast already enabled on $chan"
				return 0
			} else {
				channel set $chan +iceauto
				putserv "PRIVMSG $chan :Auto Icecast enabled on $chan"
				return 0
			}
		} elseif {$option eq "off"} {
			if {![channel get $chan iceauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto Icecast already disabled on $chan"
				return 0
			} else {
				channel set $chan -iceauto
				putserv "PRIVMSG $chan :Auto Icecast disabled on $chan"
				return 0
			}
		} else {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}iceauto on/off"
			return 0
		}
	}
	putlog "-= icecast.tcl v1.2 by PeGaSuS loaded =-"
}; # end of icecast space
