#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_subrepo() {

    COMPREPLY=()
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _subrepo_compreply "_complete -- Generate self completion"$'\n'"branch -- Create a branch with local subrepo commits since last pull."$'\n'"clean -- Remove artifacts created by fetch and branch commands."$'\n'"clone -- Add a repository as a subrepo in a subdir of your repository."$'\n'"commit -- Add subrepo branch to current history as a single commit."$'\n'"fetch -- Fetch the remote/upstream content for a subrepo."$'\n'"help -- Same as git help subrepo"$'\n'"init -- Turn an existing subdirectory into a subrepo."$'\n'"pull -- Update the subrepo subdir with the latest upstream changes."$'\n'"push -- Push a properly merged subrepo branch back upstream."$'\n'"status -- Get the status of a subrepo."$'\n'"version -- display version information about git-subrepo"

    ;;
    *)
    # subcmds
    case ${COMP_WORDS[1]} in
      _complete)
        case $COMP_CWORD in

        2)
            _subrepo_compreply "bash -- for bash"$'\n'"zsh -- for zsh"

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
      branch)

      ;;
      clean)

      ;;
      clone)

      ;;
      commit)

      ;;
      fetch)

      ;;
      help)
        case $COMP_CWORD in

        2)
            _subrepo_compreply "_complete"$'\n'"branch"$'\n'"clean"$'\n'"clone"$'\n'"commit"$'\n'"fetch"$'\n'"init"$'\n'"pull"$'\n'"push"$'\n'"status"$'\n'"version"

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          _complete)
            case $COMP_CWORD in

            3)
                _subrepo_compreply "bash"$'\n'"zsh"

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
          branch)

          ;;
          clean)

          ;;
          clone)

          ;;
          commit)

          ;;
          fetch)

          ;;
          init)

          ;;
          pull)

          ;;
          push)

          ;;
          status)

          ;;
          version)

          ;;
        esac

        ;;
        esac

      ;;
      init)

      ;;
      pull)

      ;;
      push)

      ;;
      status)

      ;;
      version)

      ;;
    esac

    ;;
    esac

}

_subrepo_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then #Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) #Remove ' -- ' and everything after
    fi
}

complete -o default -F _subrepo subrepo

