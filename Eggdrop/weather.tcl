#--------------------#
# OpenWeatherMap TCL #
#--------------------#

namespace eval weather {
    ### REQUIRED PACKAGES ###
    package require http
    package require json
    ### END OF REQUIRED PACKAGES ###

    # Trigger
    variable wTrigger "!"

    # Api Key (get your own at https://openweathermap.org/api)
    variable wApiKey ""

    # Binds
    bind pub ${::weather::wTrigger}weather ::weather::WeatherOut
    bind pub ${::weather::wTrigger}w ::weather::WeatherOut

    # Procs
    proc WeatherOut {nick uhost hand chan text} {
        set wLocation $text


        if {$wLocation eq ""} {
            putserv "PRIVMSG $chan :ERROR! Syntax ${::weather::wTrigger}weather <location> \(city,country\). Example: ${::weather::wTrigger}weather North Carolina,US"
            return 0
        }

        set token [::http::geturl "http://api.openweathermap.org/data/2.5/weather?[http::formatQuery q $wLocation appid $::weather::wApiKey]" -timeout 10000]
        set data [::http::data $token]
        set datadict [::json::json2dict $data]
        ::http::cleanup $token

        set code [dict get $datadict cod]
        if {$code != "200"} {
            set message [dict get $datadict message]
            putserv "PRIVMSG $chan :ERROR! ${wLocation}: $message"
            return 0
        }

        set name [dict get $datadict name]
        set description [dict get $datadict weather description]
        set temp [dict get $datadict main temp]
        set feels_like [dict get $datadict main feels_like]
        set temp_min [dict get $datadict main temp_min]
        set temp_max [dict get $datadict main temp_max]
        set humidity [dict get $datadict main humidity]
        set speed [dict get $datadict wind speed]

        set tempc [expr {($temp - 32) * 5.0 / 9}]
        set feels_likec [expr {($feels_like - 32) * 5.0 / 9}]
        set temp_minc [expr {($temp_min - 32) * 5.0 / 9}]
        set temp_maxc [expr {($temp_max - 32) * 5.0 / 9}]
        set speedc [expr {$speed * 1.60934}]

        putserv "PRIVMSG $chan :Location: $name :: Current: $description :: Temp: ${temp}F / ${tempc}C \(Max: ${temp_max}F / ${temp_maxc}C - Min: ${temp_min}F / ${temp_minc}C \) :: Feels like: ${feels_like}F / ${feels_likec}C :: Humidity: ${humidity}% :: Wind: ${speed} mph / ${speedc} "
        return 0
    }
}
