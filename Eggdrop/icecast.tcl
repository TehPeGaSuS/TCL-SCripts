#-------------------------------------------------------------#
# Icecast script to announce musics from your online radio    #
# This should work out of the box with single source streams  #
#                                                             #
# This script was tested with eggdrop 1.9.x and Icecast 2.4.x #
#-------------------------------------------------------------#

#------------------------------------------------------------------------#
# Commands:                                                              #
# - !music - Displays the current music playing                          #
#                                                                        #
# - !np - Does the same as !music                                        #
#                                                                        #
# - !icecast <on/off/status> - Enables/disables/checks the automatic     #
#   annoucement of the current music playing                             #
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
	variable trigger "\$"

	# URL for the json page
	variable jsonURL "http://localhost:8000/status-json.xsl"

	# Radio Name
	variable radioName "Your Radio"

	# Radio URL
	variable listenURL "https://your_radio.example.com/"

	# Time, in seconds, between each song change check
	variable pollTime "15"

	# Flag for the DJs
	variable djFlag "V"

	# Time, in minutes, to check if a source is connected?
	variable sourceCheck "1"

	# Binds
	bind pub - ${::icecast::trigger}music ::icecast::nowplaying
	bind pub - ${::icecast::trigger}np ::icecast::nowplaying
	bind pub - ${::icecast::trigger}icecast ::icecast::on_off
	bind pub - ${::icecast::trigger}addchan ::icecast::addchannel
	bind pub - ${::icecast::trigger}delchan ::icecast::delchannel

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
	setudef flag iceauto

	### Last track ###
	if {![info exists ::icecast::lastTrack]} {
		set lastTrack ""
	}

	### API polling
	bind evnt - init-server ::icecast::apiPoll
	proc apiPoll {type} {
		utimer $::icecast::pollTime [list ::icecast::announce all] 0
	}

	### Global JSON proc, that returns data to other procs
	proc getJSON {} {
		set token [::http::geturl "$::icecast::jsonURL" -timeout 10000]
		set data [::http::data $token]
		set datadict [::json::json2dict $data]
		::http::cleanup $token
		return $datadict
	}

	### Procs
	proc nowplaying {nick uhost hand chan text} {
		::icecast::announce $chan
	}

	proc announce {tchan} {
		set datadict [::icecast::getJSon]

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
		set listeners [dict get $datadict icestats source listeners]

		if {$tchan ne "all"} {
			if {[regexp c [getchanmode $tchan]]} {
				putserv "PRIVMSG $tchan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Listeners: $listeners :: Tune in: $::icecast::listenURL"
			} else {
				putserv "PRIVMSG $tchan :\002\[\00302$::icecast::radioName\003\]\002 \002DJ:\002 ${dj} :: \002Song:\002 $title :: \002Listeners:\002 $listeners :: \002Tune in:\002 $::icecast::listenURL"
			}
		} else {
			if {$::icecast::lastTrack ne "$title"} {
				set ::icecast::lastTrack "$title"

				foreach chan [channels] {
					if {[channel get $chan iceauto]} {
						if {[regexp c [getchanmode $chan]]} {
							putserv "PRIVMSG $chan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Listeners: $listeners :: Tune in: $::icecast::listenURL"
						} else {
							putserv "PRIVMSG $chan :\002\[\00302$::icecast::radioName\003\]\002 \002DJ:\002 ${dj} :: \002Song:\002 $title :: \002Listeners:\002 $listeners :: \002Tune in:\002 $::icecast::listenURL"
						}
					}
				}
			}
		}
		return 0
	}

	proc on_off {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr $hand m] || ![isop $nick $chan]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		switch $option {
			"on" {
				if {[channel get $chan iceauto]} {
					putserv "PRIVMSG $chan :Auto Icecast is already enabled on ${chan}."
					return 0
				} else {
					channel set $chan +iceauto
					putserv "PRIVMSG $chan :Auto Icecast is now enabled on ${chan}."
					return 0
				}
			}

			"off" {
				if {![channel get $chan iceauto]} {
					putserv "PRIVMSG $chan :Auto Icecast is already disabled on ${chan}."
					return 0
				} else {
					channel set $chan -iceauto
					putserv "PRIVMSG $chan :Auto Icecast is now disabled on ${chan}."
					return 0
				}
			}

			"status" {
				if {[channel get $chan iceauto]} {
					set status "enabled"
				} else {
					set status "disabled"
				}
				putserv "PRIVMSG $chan :Auto Icecast is currently $status on ${chan}."
				return 0
			}

			"default" {
				putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}icecast on/off/status"
				return
			}
		}
	}

	proc addchannel {nick uhost hand chan text} {
		set target [lindex [split $text] 0]

		if {![matchattr $hand m]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {![matchstr "#*" $target] || $target eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax ${::icecast::trigger}addchan <#channel>"
			return 0
		}

		if {[validchan $target]} {
			putserv "PRIVMSG $chan :$target already exists in my database"
			return 0
		}

		channel add $target
		putserv "PRIVMSG $chan :Joining ${target}..."
		return 0
	}

	proc delchannel {nick uhost hand chan text} {
		set target [lindex [split $text] 0]

		if {![matchattr $hand m]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {![matchstr "#*" $target] || $target eq ""} {
			putserv "PRIVMSG $chan :ERROR! Syntax ${::icecast::trigger}delchan <#channel>"
			return 0
		}

		if {![validchan $target]} {
			putserv "PRIVMSG $chan :$target doesn't exist in my database"
			return 0
		}

		channel remove $target
		putserv "PRIVMSG $chan :LeavinG ${target}..."
		return 0
	}

	putlog ".: Icecast.tcl \(11/05/2025-13:30\) by PeGaSuS loaded :."
}; # end of icecast space
