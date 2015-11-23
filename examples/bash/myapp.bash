#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_myapp() {

    COMPREPLY=()
    local program=myapp
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _myapp_compreply "_complete -- Generate self completion"$'\n'"cook -- Cook something"$'\n'"help -- Show command help"$'\n'"weather -- Weather"

    ;;
    *)
    # subcmds
    case ${COMP_WORDS[1]} in
      _complete)
        case $COMP_CWORD in

        2)
            _myapp_compreply "bash -- for bash"$'\n'"zsh -- for zsh"

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          bash)
            case $COMP_CWORD in
            *)
            case ${COMP_WORDS[$COMP_CWORD-1]} in
              --without-description)
              ;;

              *)
                _myapp_compreply "'--without-description -- generate without description'"
              ;;
            esac
            ;;
            esac
          ;;
          zsh)
          ;;
        esac

        ;;
        esac
      ;;
      cook)
        case $COMP_CWORD in
        2)
                _drink_compreply "tea"$'\n'"coffee"
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --with)
            _myapp_compreply "'almond\ milk'"$'\n'"'soy\ milk'"$'\n'"'oat\ milk'"$'\n'"'spelt\ milk'"$'\n'"'cow\ milk'"
          ;;
          --sugar|-s)
          ;;

          *)
            _myapp_compreply "'--with -- Drink with ...'"$'\n'"'--sugar -- add sugar'"$'\n'"'-s -- add sugar'"
          ;;
        esac
        ;;
        esac
      ;;
      help)
        case $COMP_CWORD in

        2)
            _myapp_compreply "_complete"$'\n'"cook"$'\n'"weather"

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          _complete)
            case $COMP_CWORD in

            3)
                _myapp_compreply "bash"$'\n'"zsh"

            ;;
            *)
            # subcmds
            case ${COMP_WORDS[3]} in
              bash)
              ;;
              zsh)
              ;;
            esac

            ;;
            esac
          ;;
          cook)
          ;;
          weather)
            case $COMP_CWORD in

            3)
                _myapp_compreply "cities"$'\n'"countries"$'\n'"show"

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
      weather)
        case $COMP_CWORD in

        2)
            _myapp_compreply "cities -- show list of cities"$'\n'"countries -- show list of countries"$'\n'"show"

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          cities)
            case $COMP_CWORD in
            *)
            case ${COMP_WORDS[$COMP_CWORD-1]} in
              --country)
              ;;

              *)
                _myapp_compreply "'--country -- country name'"
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
                    local param_country=`$program 'weather' 'countries'`
                    _myapp_compreply "$param_country"
            ;;
            4)
                    local param_city=`$program 'weather' 'cities' '--country' "${COMP_WORDS[$COMP_CWORD-1]}"`
                    _myapp_compreply "$param_city"
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
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then #Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) #Remove ' -- ' and everything after
    fi
}

complete -o default -F _myapp myapp

