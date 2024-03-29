###
# IdleRPG Auto Login
###
# This scripts makes your bot automatically log in into your IdleRPG account
# Just edit the script to fit your needs and load it to your bot.
# Happy idling
###

namespace eval idlerpg {
    # IdleRG Channel
    variable Chan "#IdleRPG"

    # IdleRPG Bot
    variable Bot "IdleRPG"

    # IdleRPG Character Name
    variable Character "CHARACTER"

    # IdleRPG Character Password
    variable Password "PASSWORD"

    ### Binds
    # Join
    bind join - * ::idlerpg::idleJoin

    ### Procs
    proc idleJoin {nick uhost hand chan} {
        if {$chan eq "$::idlerpg::Chan"} {
            if {$nick eq "$::idlerpg::Bot"} {
                putlog "Sending LOGIN command because $::idlerpg::Bot bot just entered the channel"
                putlog "This is just in case we need to relogin"
                putserv "PRIVMSG $nick :LOGIN $::idlerpg::Character $::idlerpg::Password"
                return 0
            }
            if {$nick eq "$::botnick"} {
                putlog "Sending LOGIN command to $::idlerpg::Bot"
                putserv "PRIVMSG $::idlerpg::Bot :LOGIN $::idlerpg::Character $::idlerpg::Password"
                return 0
            }
        }
    }
}

putlog "-= IdleRPG Auto Login v1.0 by PeGaSuS loaded =-"
