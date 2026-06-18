#####
# Nickname/Uhost tracker script
# Egghelp version, donations to slennox are welcomed. :P
# Original version from speechles (?)
# Enhanced by PeGaSuS
#####

#####
# We need at least TCL >=8.5 due to the -nocase in lsearch
# Thanks mezen for the reminder
#####
if {[catch {package require Tcl 8.5} err]} {
    putlog "ERROR: Tcl 8.5 or newer is required — unloading script."
    return
}

##########
# should duplicate nicknames be allowed?
##########
# 0 = no, 1 and above = yes
##########
set dupes 0

##########
# Maximum number of nicks shown per output line
##########
set nicks_per_line 15

##########
# Maximum number of lines the bot will output per join/nick-change event
##########
# 0 = unlimited
##########
set max_output_lines 5

##########
# Send nicktracking information to the specified channel(s)/nickname(s). You can set several destinations
# Example
# set channelmap {
#	"#channel1" "#channel2"
#	"#otherchannel" "#channel3 #channel4 somenick"
# }
#
##########
set channelmap {
    "#amicizia" "#camelot"
    "#thelounge" "#thelounge-ops"
}

##########
# Nicks to alert in case the channel doesn't have a backchan or there's no
# channel -> backchan mapping
##########
set alertnicks {
    "NullPointer"
}

##########
# Binds
##########
#bind nick - * nick_nickchange
bind join - * join_onjoin
##########
# End of binds
##########

##########
# Channel flag
##########
setudef flag nicktrack

##########
# Procs
##########

##########
# check for nick changes
##########
proc nick_nickchange {nick uhost hand chan newnick} {
    if {![channel get $chan "nicktrack"]} {
        return 0
    }

    if {$nick eq "$::botnick"} {
        return 0
    }

    join_onjoin $newnick $uhost $hand $chan
    return 0
}

##########
# check for joins
##########
proc join_onjoin {nick uhost hand chan} {
    global botnick dupes channelmap list_length alertnicks nicks_per_line max_output_lines
    if {![channel get $chan "nicktrack"]} {
        return 0
    }

    if {$nick eq "$::botnick"} {
        return 0
    }

    # keep everything lowercase for simplicity.
    set ch [strlwr $chan]
    set filename "[string trim "$ch" #]_nicklist.txt"
    set uhost [strlwr $uhost]

    # read the file
    if {![file exists $filename]} {
        set file [open $filename "w"]
        close $file
    }

    set file [open $filename "r"]
    set text [split [read $file] \n]
    close $file
    # locate a duplicate host
    set found [lsearch -glob $text "*<$uhost"]
    if {$found < 0} {
        # host isn't found so let's append the nick and host to our file
        set file [open $filename "a"]
        puts $file "$nick<$uhost"
        close $file
    } else {
        # the host exists, so set our list of nicks for that host
        set nicks [lindex [split [lindex $text $found] "<"] 0]
        # is the nick already known for that host?
        set nlist [split $nicks ","]
        if {[set pos [lsearch -nocase $nlist $nick]] != -1} { set nlist [lreplace $nlist $pos $pos] }

        # Build the (possibly truncated) display list, then chunk it into
        # groups of $nicks_per_line, capped at $max_output_lines lines total.
        set displaylist $nlist
        set remaining 0
        if {$max_output_lines > 0} {
            set max_shown [expr {$nicks_per_line * $max_output_lines}]
            if {[llength $displaylist] > $max_shown} {
                set remaining [expr {[llength $displaylist] - $max_shown}]
                set displaylist [lrange $displaylist 0 [expr {$max_shown - 1}]]
            }
        }

        set chunks [list]
        for {set i 0} {$i < [llength $displaylist]} {incr i $nicks_per_line} {
            lappend chunks [join [lrange $displaylist $i [expr {$i + $nicks_per_line - 1}]] { }]
        }
        if {$remaining > 0 && [llength $chunks]} {
            set last [expr {[llength $chunks] - 1}]
            lset chunks $last "[lindex $chunks $last] (+$remaining altri)"
        }

        # Send messages to the defined channels
        if {$ch in [dict keys $channelmap]} {
            set bkc [dict get $channelmap $ch]
            foreach bkct [split $bkc] {
                foreach c $chunks {
                    putquick "PRIVMSG $bkct :\[\00302$chan\003\] \00304$nick\003 ha usato \00304$c\003"
                }
            }
        } else {
            # Send a notice to channel operators if bot is chanop
            if {[isop $botnick $ch]} {
                foreach c $chunks {
                    putquick "NOTICE @$ch :\00304$nick\003 ha usato: \00304$c\003"
                }
            } else {
                # Send a message to the nicks on the list if none of the conditions above is met
                if {[llength $alertnicks]} {
                    foreach n [split $alertnicks] {
                        foreach c $chunks {
                            putquick "PRIVMSG $n :\[\00302$chan\003\] \00304$nick\003 ha usato: \00304$c\003"
                        }
                    }
                }
            }
        }

        # To make it output to partyline remove the # the begins the line below.
        #if {[string length [join $nlist]]} { putloglev d * "*** $nick on $chan is also known as :[join $nlist ", "]." }

        set known [lsearch -exact -nocase [split $nicks ","] $nick]
        if {($known != -1) && ($dupes < 1)} {
            # if the nick is known return
            return
        } else {
            # otherwise add the nick to the nicks for that host
            set text [lreplace $text $found $found "$nick,$nicks<$uhost"]
        }
        # now lets write the new list to the file
        set file [open $filename "w"]
        foreach line $text {
            if {[string length $line]} {
                puts $file "$line"
            }
        }
        close $file
    }
    return 0
}

putlog "Nickname/Uhost tracker enabled."
