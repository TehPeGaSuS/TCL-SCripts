#--------------------#
# OpenWeatherMap TCL #
#--------------------#

namespace eval weather {
    ### REQUIRED PACKAGES ###
    package require http; # apt install tcllib
    package require json; # apt install tcllib
    package require tls; #apt install tcl-tls
    ::http::register https 443 [list ::tls::socket -autoservername true]
    ### END OF REQUIRED PACKAGES ###

    # Trigger
    variable wTrigger "!"

    # Api Key (get your own at https://openweathermap.org/api)
    variable wApiKey "API_KEY"

    # Binds
    bind pub * ${::weather::wTrigger}weather ::weather::WeatherOut
    bind pub * ${::weather::wTrigger}w ::weather::WeatherOut

    # Procs
    proc WeatherOut {nick uhost hand chan text} {
        set wLocation $text


        if {$wLocation eq ""} {
            putserv "PRIVMSG $chan :ERROR! Syntax ${::weather::wTrigger}weather <location>. Example: ${::weather::wTrigger}weather North Carolina, US"
            return 0
        }

        set nominatim [::http::geturl "https://nominatim.openstreetmap.org/search?[http::formatQuery q $wLocation limit 1 format jsonv2]" -timeout 10000]
        set nominatimData [::http::data $nominatim]
        set nominatimDict [::json::json2dict $nominatimData]
        ::http::cleanup $nominatim
        set nominatimLocation [lindex $nominatimDict 0]
        set wLocationLat [dict get $nominatimLocation lat]
        set wLocationLon [dict get $nominatimLocation lon]
        set wLocationName [dict get $nominatimLocation display_name]

        set token [::http::geturl "https://api.openweathermap.org/data/2.5/weather?[http::formatQuery lat $wLocationLat lon $wLocationLon appid $::weather::wApiKey units imperial]" -timeout 10000]
        set data [::http::data $token]
        set datadict [::json::json2dict $data]
        ::http::cleanup $token

        set code [dict get $datadict cod]

        if {$code == 200} {
            set name [dict get $datadict name]
            set weatherList [lindex [dict get $datadict weather] 0]
            set description [dict get $weatherList description]
            set temp [format "%.1f" [dict get $datadict main temp]]
            set feels_like [format "%.1f" [dict get $datadict main feels_like]]
            set humidity [dict get $datadict main humidity]
            set speed [format "%.1f" [dict get $datadict wind speed]]

            set tempc [format "%.1f" [expr {($temp - 32) * 5.0 / 9}]]
            set feels_likec [format "%.1f" [expr {($feels_like - 32) * 5.0 / 9}]]
            set speedc [format "%.1f" [expr {$speed * 1.60934}]]
            putserv "PRIVMSG $chan :Location: $wLocationName :: Current: $description :: Temp: ${temp}F/${tempc}C :: Feels like: ${feels_like}F/${feels_likec}C :: Humidity: ${humidity}% :: Wind: ${speed}mph/${speedc}kmh"
            return 0
        } else {
            set message [dict get $datadict message]
            putserv "PRIVMSG $chan :${wLocation}: $message"
            return 0
        }
    }
    putlog ".: Weather.tcl loaded :."
}
