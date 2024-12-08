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
# - !iceauto <all/hourly/off/status> - Enables/disables the automatic    #
#   annoucement of the current music playing (check is done every minute #
#   for `all`, but the music is only announced if it has changed)        #
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
	variable jsonURL "http://radio.domain.tld:8000/status-json.xsl"

	# Radio Name
	variable radioName "Your Radio"

	# Radio URL
	variable listenURL "https://radio.domain.tld/"

	# Binds
	bind cron - "* * * * *" ::icecast::autoplaying
	bind cron - "0 * * * *" ::icecast::hourly
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
	setudef flag iceall
	setudef flag icehourly

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

	proc autoplaying {minute hour day month weekday} {
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
					if {[channel get $chan iceall]} {
						if {[regexp c [getchanmode $chan]]} {
							putserv "PRIVMSG $chan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Tune in: $::icecast::listenURL"		
						} else {
							putserv "PRIVMSG $chan :\002\[\00302$::icecast::radioName\003\]\002 \002DJ:\002 ${dj} :: \002Song:\002 $title :: \002Tune in:\002 $::icecast::listenURL"
						}
					}
				}
			}
		}
	}

	proc hourly {minute hour day month weekday} {

		set token [::http::geturl "$::icecast::jsonURL" -timeout 10000]
		set data [::http::data $token]
		set datadict [::json::json2dict $data]
		::http::cleanup $token

		if {![dict exists $datadict icestats source]} {
			return 0
		}

		set dj [dict get $datadict icestats source server_name]
		set title [dict get $datadict icestats source title]
		
		foreach chan [channels] {
			if {[channel get $chan icehourly]} {
				if {[regexp c [getchanmode $chan]]} {
					putserv "PRIVMSG $chan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Tune in: $::icecast::listenURL"
				} else {
					putserv "PRIVMSG $chan :\002\[\00302$::icecast::radioName\003\]\002 \002DJ:\002 ${dj} :: \002Song:\002 $title :: \002Tune in:\002 $::icecast::listenURL"
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

		switch $option {
			"on" {
				if {[channel get $chan icecast]} {
					putserv "PRIVMSG $chan :Icecast is already enabled on ${chan}."
					return 0
				} else {
					channel set $chan +icecast
					putserv "PRIVMSG $chan :Icecast is now enabled on ${chan}."
					return 0
				}
			}
			"off" {
				if {![channel get $chan icecast]} {
					putserv "PRIVMSG $chan :Icecast is already disabled on ${chan}."
					return 0
				} else {
					channel set $chan -icecast
					putserv "PRIVMSG $chan :Icecast is now disabled on ${chan}."
					return 0
				}
			}
			"status" {
				if {[channel get $chan icecast]} {
					set status "enabled"
				} else {
					set status "disabled"
				}
				putserv "PRIVMSG $chan :Icecast is $status on ${chan}."
				return 0
			}
			"default" {
				putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}icecast on/off/status"
				return
			}
		}
	}

	proc auto_onoff {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr [nick2hand $nick] m]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		switch $option {
			"all" {
				if {[channel get $chan iceall]} {
					putserv "PRIVMSG $chan :ERROR! Auto Icecast (all) already enabled on ${chan}."
					return 0
				}
				if {[channel get $chan icehourly]} {
					channel set $chan -icehourly
					channel set $chan +iceall
					putserv "PRIVMSG $chan :Auto Icecast (all) enabled on ${chan}."
					return 0
				}
				channel set $chan +iceall
				putserv "PRIVMSG $chan :Auto Icecast (all) enabled on ${chan}."
				return 0
			}
			"hourly" {
				if {[channel get $chan icehourly]} {
					putserv "PRIVMSG $chan :ERROR! Auto Icecast (hourly) already enabled on ${chan}."
					return 0
				}
				if {[channel get $chan iceall]} {
					channel set $chan -iceall
					channel set $chan +icehourly
					putserv "PRIVMSG $chan :Auto Icecast (hourly) enabled on ${chan}."
					return 0
				}
				channel set $chan +icehourly
				putserv "PRIVMSG $chan :Auto Icecast (hourly) enabled on ${chan}."
				return 0
			}
			"off" {
				if {(![channel get $chan iceall] || ![channel get $chan icehourly])} {
					putserv "PRIVMSG $chan :ERROR! Auto Icecast already disabled on ${chan}."
					return 0
				} else {
					if {[channel get $chan iceall]} {
						channel set $chan -iceall
					}
					if {[channel get $chan icehourly]} {
						channel set $chan -icehourly
					}
					putserv "PRIVMSG $chan :Auto Icecast disabled on ${chan}."
					return 0
				}
			}
			"status" {
				if {[channel get $chan icehourly]} {
					set status "hourly"
				} elseif {[channel get $chan iceall]} {
					set status "all"
				} else {
					set status "disabled"
				}
				putserv "PRIVMSG $chan :Iceauto is $status on ${chan}."
				return 0
			}
			"default" {
				putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}iceauto all/hourly/off/status"
				return 0
			}
		}
	}
	putlog "-= icecast.tcl v1.2 by PeGaSuS loaded =-"
}; # end of icecast space
