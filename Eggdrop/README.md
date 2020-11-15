# Script list #

## WARNING ##
Some of those scripts only work with [eggdrop](https://github.com/eggheads/eggdrop) 1.9 (currently under development).\
Please check below the scripts that requires it.
#

### Cban ###
**Requires eggdrop 1.9**

The [cban](https://github.com/PeGaSuS-Coder/TCL-SCripts/blob/master/Eggdrop/cban.tcl) script was made to make channel operators life easier.\
It checks for channel access instead internal bot access.
#### Commands
**cban \<nick>** - bans the nick in the format `*!*user@host` (nick needs to be in the channel)\
**uncban \<mask|last>** - Removes the specified mask or the last ban if `last` is specified instead a mask\
**bans** - Sends a PM to the user showing the current internal ban list for the channel\
**addban \<mask>** - Adds the specified mask to the bot ban list (*NOTE:* this doesn't do any sanity checks, so you can end up banning everyone)\
**tban \<nick>** - Adds a temporary ban in the specified nick (nick must be on channel) with the duration specified on `banDuration` variable
#

### OMDb ###
