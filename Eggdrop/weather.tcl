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

    # Default metric units (metric or imperial)
    variable wDefMetrics "metric"

    # Binds
    bind pub ${::weather::wTrigger}weather ::weather::WeatherOut
    bind pub ${::weather::wTrigger}w ::weather::WeatherOut

    # Procs
    proc WeatherOut {nick uhost hand chan text} {
        set wLocation [lindex [split $text] 0]
        set wMetrics [lindex [split $text] 2]


        if {$wMetrics eq "" || $wMetrics ne "metric" || $wMetrics ne "imperial"} {
            set wMetrics "$::weather::wDefMetrics"
        }

        if {$wLocation eq ""} {
            putserv "PRIVMSG $chan :ERROR! Syntax ${::weather::wTrigger}weather <location> \(city,country\) \[--units <units \(metric or imperial\)>\]"
            putserv "PRIVMSG $chan :Example: ${::weather::wTrigger}weather Colorado,US --units metric"
            return 0
        }

        set token [::http::geturl "http://api.openweathermap.org/data/2.5/weather?[http::formatQuery q $wLocation appid $::weather::wApiKey units $wMetrics]" -timeout 10000]
        set data [::http::data $token]
        set datadict [::json::json2dict $data]
        ::http::cleanup $token

        set name [dict get $datadict name]
        set description [dict get $datadict weather description]
        set temp [dict get $datadict main temp]
        set feels_like [dict get $datadict main feels_like]
        set temp_min [dict get $datadict main temp_min]
        set temp_max [dict get $datadict main temp_max]
        set humidity [dict get $datadict main humidity]
        set speed [dict get $datadict wind speed]

        if {$wMetrics eq "metric"} {
            set tempUnit "C"
            set windUnit "kmh"
        } else {
            set tempUnit "F"
            set windUnit "mph"
        }

        putserv "PRIVMSG $chan :Location: $name :: Current: $description :: Temp: ${temp}$tempUnit \(Max: ${temp_max}$tempUnit - Min: ${temp_min}$tempUnit\) :: Feels like: ${feels_like}$tempUnit :: Humidity: ${humidity}% :: Wind: $speed $windUnit"
        return 0
    }
}
