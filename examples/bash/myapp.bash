#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_myapp() {

    COMPREPLY=()
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _myapp_compreply "_complete -- Generate self completion"$'\n'"cook -- Cook something"$'\n'"help -- Show command help"

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
                _myapp_compreply "tea"$'\n'"coffee"
        ;;
        esac
      ;;
      help)
        case $COMP_CWORD in

        2)
            _myapp_compreply "_complete"$'\n'"cook"

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

