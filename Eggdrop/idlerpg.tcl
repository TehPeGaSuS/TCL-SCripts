#--------------------#
# IdleRPG Auto Login #
#--------------------#

#----------------------------------------------------------------------------#
# This scripts makes your bot automatically log in into your IdleRPG account #
# Just edit the script to fit your needs and load it to your bot.            #
#                                                                            #
# You can also register your character and change its alignment with the     #
# following private message commands:                                        #
#                                                                            #
#   > register - Registers your character                                    #
#   > align <alignment> - Changes your character alignment                   #
#   > login - Logs in your character                                         #
#                                                                            #
# HAPPY IDLING!!!                                                            #
#----------------------------------------------------------------------------#

namespace eval idlerpg {
    # IdleRG Channel
    variable idleChan "#idle"

    # IdleRPG Bot
    variable idleBot "IdleBot"

    # IdleRPG Character Name (Can be up to 16 letters long)
    variable idleChar "YOUR_CHARACTER"

    # IdleRPG Character Password (Can be up to 8 letters long)
    variable idlePass "CHARACTER_PASSWORD"

    # IdleRPG Character Class (Can be up to 30 letters long)
    variable idleClass "YOUR CHARACTER CLASS"

    ### Binds
    # Join (automatic)
    bind join - "$::idlerpg::Chan *" ::idlerpg::idleJoin

    # Login (private message command)
    bind msg login ::idlerpg::idleLogin

    # Register Character (private message command)
    bind msg - register ::idlerpg::idleRegister

    # Change Character Alignment (private message command)
    bind msg - align ::idlerpg::idleAlign


    ### Procs
    proc idleJoin {nick uhost hand chan} {
        if {$chan eq $::idleChan} {
            if {$nick eq "$::botnick"} {
                putloglev o * "Identifying to $::idlerpg::idleBot since we just connected..."
                putserv "PRIVMSG $::idlerpg::idleBot :LOGIN $::idlerpg::idleChar $::idlerpg::idlePass"
                return 0
            }

            if {$nick eq "$::idlerpg::idleBot"} {
                putloglev o * "Sending LOGIN command to $::idlerpg::idleBot since it just returned..."
                putserv "PRIVMSG $::idlerpg::idleBot :LOGIN $::idlerpg::idleChar $::idlerpg::idlePass"
                return 0
            }
        }
    }

    proc idleLogin {nick uhost hand text} {
        if {![matchattr $hand n]} {
            putserv "PRIVMSG $nick :ERROR! You don't have access, ${nick}!"
            putserv "PRIVMSG $nick :If you're the bot owner, identify yourself with: /msg $::botnick ident <password> ${nick}"
            return 0
        }

        if {![botonchan $::idlerpg::idleChan]} {
            putserv "PRIVMSG $nick :ERROR! I'm not on ${::idlerpg::idleChan}, ${nick}!"
            return 0
        }

        putserv "PRIVMSG $::idlerpg::idleBot :LOGIN $::idlerpg::idleChar $::idlerpg::idlePass"
        putserv "PRIVMSG $nick :${::idlerpg::idleChar} logged in!"
        return 0
    }

    proc idleRegister {nick uhost hand text} {
        if {![matchattr $hand n]} {
            putserv "PRIVMSG $nick :ERROR! You don't have access, ${nick}!"
            putserv "PRIVMSG $nick :If you're the bot owner, identify yourself with: /msg $::botnick ident <password> ${nick}"
            return 0
        }

        if {![botonchan $::idlerpg::idleChan]} {
            putserv "PRIVMSG $nick :ERROR! I'm not on ${::idlerpg::idleChan}, ${nick}!"
            return 0
        }

        putserv "PRIVMSG $::idlerpg::idleBot :REGISTER $::idlerpg::idleChar $::idlerpg::idlePass $::idlerpg::idleClass"
        putserv "PRIVMSG $nick :${::idlerpg::idleChar} registered!"
        return 0
    }

    proc idleAlign {nick uhost hand text} {
        set alignm [lindex [split $text] 0]

        if {![matchattr $hand n]} {
            putserv "PRIVMSG $nick :ERROR! You don't have access, ${nick}!"
            putserv "PRIVMSG $nick :If you're the bot owner, identify yourself with: /msg $::botnick ident <password> ${nick}"
            return 0
        }

        if {![botonchan $::idlerpg::idleChan]} {
            putserv "PRIVMSG $nick :ERROR! I'm not on ${::idlerpg::idleChan}, ${nick}!"
            return 0
        }

        switch $alignm {
            "neutral" {
                putserv "PRIVMSG $::idlerpg::idleBot :ALIGN neutral"
                putserv "PRIVMSG $nick :${::idlerpg::idleChar} alignment changed to neutral."
                return 0
            }

            "good" {
                putserv "PRIVMSG $::idlerpg::idleBot :ALIGN good"
                putserv "PRIVMSG $nick :${::idlerpg::idleChar} alignment changed to good."
                return 0
            }

            "evil" {
                putserv "PRIVMSG $::idlerpg::idleBot :ALIGN evil"
                putserv "PRIVMSG $nick :${::idlerpg::idleChar} alignment changed to evil."
                return 0
            }

            "default" {
                putserv "PRIVMSG $nick :ERROR! Possible alignments: neutral, good, evil."
                return 0
            }
        }
    }

    putlog "-= IdleRPG Auto Login v13.05.2025-00.30 by PeGaSuS loaded =-"
}
