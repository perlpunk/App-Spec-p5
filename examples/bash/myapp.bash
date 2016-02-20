#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_myapp() {

    COMPREPLY=()
    local program=myapp
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _myapp_compreply '_complete  -- Generate self completion'$'\n''cook       -- Cook something'$'\n''help       -- Show command help'$'\n''palindrome -- Check if a string is a palindrome'$'\n''weather    -- Weather'

    ;;
    *)
    # subcmds
    case ${COMP_WORDS[1]} in
      _complete)
        case $COMP_CWORD in
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --verbose|-v)
          ;;
          --help|-h)
          ;;
          --name)
          ;;
          --zsh)
          ;;
          --bash)
          ;;

          *)
            _myapp_compreply "'--verbose -- be verbose'"$'\n'"'-v        -- be verbose'"$'\n'"'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"$'\n'"'--name    -- name of the program'"$'\n'"'--zsh     -- for zsh'"$'\n'"'--bash    -- for bash'"
          ;;
        esac
        ;;
        esac
      ;;
      cook)
        case $COMP_CWORD in
        2)
                _myapp_compreply "tea"$'\n'"coffee"
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --verbose|-v)
          ;;
          --help|-h)
          ;;
          --with)
            _myapp_compreply "'almond\ milk'"$'\n'"'soy\ milk'"$'\n'"'oat\ milk'"$'\n'"'spelt\ milk'"$'\n'"'cow\ milk'"
          ;;
          --sugar|-s)
          ;;

          *)
            _myapp_compreply "'--verbose -- be verbose'"$'\n'"'-v        -- be verbose'"$'\n'"'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"$'\n'"'--with    -- Drink with ...'"$'\n'"'--sugar   -- add sugar'"$'\n'"'-s        -- add sugar'"
          ;;
        esac
        ;;
        esac
      ;;
      help)
        case $COMP_CWORD in

        2)
            _myapp_compreply '_complete '$'\n''cook      '$'\n''palindrome'$'\n''weather   '

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          _complete)
          ;;
          cook)
          ;;
          palindrome)
          ;;
          weather)
            case $COMP_CWORD in

            3)
                _myapp_compreply 'cities   '$'\n''countries'$'\n''show     '

            ;;
            *)
            # subcmds
            case ${COMP_WORDS[3]} in
              cities)
              ;;
              countries)
              ;;
              show)
              ;;
            esac

            ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      palindrome)
        case $COMP_CWORD in
        2)
                _myapp_palindrome_param_string_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --verbose|-v)
          ;;
          --help|-h)
          ;;

          *)
            _myapp_compreply "'--verbose -- be verbose'"$'\n'"'-v        -- be verbose'"$'\n'"'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"
          ;;
        esac
        ;;
        esac
      ;;
      weather)
        case $COMP_CWORD in

        2)
            _myapp_compreply 'cities    -- show list of cities'$'\n''countries -- show list of countries'$'\n''show      -- Show Weather forecast'

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          cities)
            case $COMP_CWORD in
            *)
            case ${COMP_WORDS[$COMP_CWORD-1]} in
              --verbose|-v)
              ;;
              --help|-h)
              ;;
              --country|-c)
                _myapp_weather_cities_option_country_completion
              ;;

              *)
                _myapp_compreply "'--verbose -- be verbose'"$'\n'"'-v        -- be verbose'"$'\n'"'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"$'\n'"'--country -- country name(s)'"$'\n'"'-c        -- country name(s)'"
              ;;
            esac
            ;;
            esac
          ;;
          countries)
          ;;
          show)
            case $COMP_CWORD in
            3)
                    _myapp_weather_show_param_country_completion
            ;;
            4)
                    _myapp_weather_show_param_city_completion
            ;;
            *)
            case ${COMP_WORDS[$COMP_CWORD-1]} in
              --verbose|-v)
              ;;
              --help|-h)
              ;;
              --temperature|-T)
              ;;
              --celsius|-C)
              ;;
              --fahrenheit|-F)
              ;;

              *)
                _myapp_compreply "'--verbose     -- be verbose'"$'\n'"'-v            -- be verbose'"$'\n'"'--help        -- Show command help'"$'\n'"'-h            -- Show command help'"$'\n'"'--temperature -- show temperature'"$'\n'"'-T            -- show temperature'"$'\n'"'--celsius     -- show temperature in celcius'"$'\n'"'-C            -- show temperature in celcius'"$'\n'"'--fahrenheit  -- show temperature in fahrenheit'"$'\n'"'-F            -- show temperature in fahrenheit'"
              ;;
            esac
            ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
    esac

    ;;
    esac

}

_myapp_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) # Remove ' -- ' and everything after
        COMPREPLY="$(echo -e "$COMPREPLY" | sed -e 's/[[:space:]]*$//')"
    fi
}

_myapp_palindrome_param_string_completion() {
    local param_string=`cat /usr/share/dict/words | perl -nle'print if $_ eq reverse $_'
`
    _myapp_compreply "$param_string"
}
_myapp_weather_cities_option_country_completion() {
    local param_country=`$program 'weather' 'countries'`
    _myapp_compreply "$param_country"
}
_myapp_weather_show_param_country_completion() {
    local __dynamic_completion
    __dynamic_completion=`PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='country' ${COMP_WORDS[@]}`
    _myapp_compreply "$__dynamic_completion"
}
_myapp_weather_show_param_city_completion() {
    local __dynamic_completion
    __dynamic_completion=`PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='city' ${COMP_WORDS[@]}`
    _myapp_compreply "$__dynamic_completion"
}


complete -o default -F _myapp myapp

