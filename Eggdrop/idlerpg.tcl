#--------------------#
# IdleRPG Auto Login #
#--------------------#

#----------------------------------------------------------------------------#
# This scripts makes your bot automatically log in into your IdleRPG account #
# Just edit the script to fit your needs and load it to your bot.            #
# HAPPY IDLING!!!                                                            #
#----------------------------------------------------------------------------#

namespace eval idlerpg {
    # IdleRG Channel
    variable Chan "##idlerpg"

    # IdleRPG Bot
    variable Bot "IdleRPGbot"

    # IdleRPG Character Name
    variable Character "CHARACTER"

    # IdleRPG Character Password
    variable Password "PASSWORD"

    ### Binds
    # Join
    bind join - "$::idlerpg::Chan *" ::idlerpg::idleJoin


    ### Procs
    proc idleJoin {nick uhost hand chan} {
        if {$nick eq "$::botnick"} {
            putlog "Identifying to $::idlerpg::Bot since we just connected..."
            putserv "PRIVMSG $::idlerpg::Bot :LOGIN $::idlerpg::Character $::idlerpg::Password"
            return 0
        }

        if {$nick eq "$::idlerpg::Bot"} {
            putlog "Sending LOGIN command to $::idlerpg::Bot since it just returned..."
            putserv "PRIVMSG $::idlerpg::Bot :LOGIN $::idlerpg::Character $::idlerpg::Password"
            return 0
        }
    }
}; # end of idlerpg namespace

putlog "-= IdleRPG Auto Login v2.0 by PeGaSuS loaded =-"
