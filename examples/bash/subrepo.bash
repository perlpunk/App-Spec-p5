#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_subrepo() {

    COMPREPLY=()
    local program=subrepo
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $COMP_CWORD - 1`
    MYWORDS=("${COMP_WORDS[@]:1:$COMP_CWORD}")

    FLAGS=('--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=()
    __subrepo_handle_options_flags

    case $INDEX in

    0)
        __comp_current_options || return
        __subrepo_dynamic_comp 'commands' 'branch'$'\t''Create a branch with local subrepo commits since last pull.'$'\n''clean'$'\t''Remove artifacts created by '"'"'fetch'"'"' and '"'"'branch'"'"' commands.'$'\n''clone'$'\t''Add a repository as a subrepo in a subdir of your repository.'$'\n''commit'$'\t''Add subrepo branch to current history as a single commit.'$'\n''fetch'$'\t''Fetch the remote/upstream content for a subrepo.'$'\n''help'$'\t''Same as '"'"'git help subrepo'"'"''$'\n''init'$'\t''Turn an existing subdirectory into a subrepo.'$'\n''pull'$'\t''Update the subrepo subdir with the latest upstream changes.'$'\n''push'$'\t''Push a properly merged subrepo branch back upstream.'$'\n''status'$'\t''Get the status of a subrepo.'$'\n''version'$'\t''display version information about git-subrepo'

    ;;
    *)
    # subcmds
    case ${MYWORDS[0]} in
      _complete)
        FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
        OPTIONS+=('--name' 'name of the program')
        __subrepo_handle_options_flags
          case $INDEX in
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --name)
              ;;

            esac
            ;;
        esac
      ;;
      _pod)
        FLAGS+=()
        OPTIONS+=()
        __subrepo_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
      branch)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=()
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_branch_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      clean)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=()
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_clean_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      clone)
        FLAGS+=('--force' 'reclone (completely replace) an existing subdir.' '-f' 'reclone (completely replace) an existing subdir.')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch')
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          2)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --branch|-b)
              ;;

            esac
            ;;
        esac
      ;;
      commit)
        FLAGS+=()
        OPTIONS+=()
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_commit_param_subrepo_completion
          ;;
          2)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      fetch)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=()
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_fetch_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      help)
        FLAGS+=()
        OPTIONS+=()
        __subrepo_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __subrepo_dynamic_comp 'commands' 'branch'$'\n''clean'$'\n''clone'$'\n''commit'$'\n''fetch'$'\n''init'$'\n''pull'$'\n''push'$'\n''status'$'\n''version'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          _complete)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          _pod)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          branch)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          clean)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          clone)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          commit)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          fetch)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          init)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          pull)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          push)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          status)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          version)
            FLAGS+=()
            OPTIONS+=()
            __subrepo_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
        esac

        ;;
        esac
      ;;
      init)
        FLAGS+=()
        OPTIONS+=('--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--branch' 'Upstream branch' '-b' 'Upstream branch')
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --remote|-r)
              ;;
              --branch|-b)
              ;;

            esac
            ;;
        esac
      ;;
      pull)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch' '--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--update' 'update' '-u' 'update')
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_pull_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --branch|-b)
              ;;
              --remote|-r)
              ;;
              --update|-u)
              ;;

            esac
            ;;
        esac
      ;;
      push)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch' '--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--update' 'update' '-u' 'update')
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_push_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --branch|-b)
              ;;
              --remote|-r)
              ;;
              --update|-u)
              ;;

            esac
            ;;
        esac
      ;;
      status)
        FLAGS+=()
        OPTIONS+=('--quiet' 'Just print names' '-q' 'Just print names')
        __subrepo_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_status_param_subrepo_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --quiet|-q)
              ;;

            esac
            ;;
        esac
      ;;
      version)
        FLAGS+=()
        OPTIONS+=()
        __subrepo_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
    esac

    ;;
    esac

}

_subrepo_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) # Remove ' -- ' and everything after
        COMPREPLY="$(echo -e "$COMPREPLY" | sed -e 's/[[:space:]]*$//')"
    fi
}

_subrepo_branch_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_clean_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_commit_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_fetch_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_pull_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_push_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}
_subrepo_status_param_subrepo_completion() {
    local param_subrepo=`$program 'status' '--quiet'`
    _subrepo_compreply "$param_subrepo"
}

__subrepo_dynamic_comp() {
    local argname="$1"
    local arg="$2"
    local comp name desc cols desclength formatted
    local max=0

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        if [[ "${#name}" -gt "$max" ]]; then
            max="${#name}"
        fi
    done <<< "$arg"

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        desc="${desc/*$'\t'}"
        if [[ -n "$desc" && "$desc" != "$name" ]]; then
            # TODO portable?
            cols=`tput cols`
            [[ -z $cols ]] && cols=80
            desclength=`expr $cols - 4 - $max`
            formatted=`printf "'%-*s -- %-*s'" "$max" "$name" "$desclength" "$desc"`
            comp="$comp$formatted"$'\n'
        else
            comp="$comp'$name'"$'\n'
        fi
    done <<< "$arg"
    _subrepo_compreply "$comp"
}

function __subrepo_handle_options() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#OPTIONS[@]}; j+=2))
        do
            local option="${OPTIONS[$j]}"
            if [[ "$word" == "$option" ]]; then
                found=1
                i=`expr $i + 1`
                break
            fi
        done
        if [[ -n $found && $i -lt $max ]]; then
            INDEX=`expr $INDEX - 2`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

function __subrepo_handle_flags() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#FLAGS[@]}; j+=2))
        do
            local flag="${FLAGS[$j]}"
            if [[ "$word" == "$flag" ]]; then
                found=1
                break
            fi
        done
        if [[ -n $found ]]; then
            INDEX=`expr $INDEX - 1`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

__subrepo_handle_options_flags() {
    __subrepo_handle_options
    __subrepo_handle_flags
}

__comp_current_options() {
    local always="$1"
    if [[ -n $always || ${MYWORDS[$INDEX]} =~ ^- ]]; then

      local options_spec=''
      local j=

      for ((j=0; j<${#FLAGS[@]}; j+=2))
      do
          local name="${FLAGS[$j]}"
          local desc="${FLAGS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done

      for ((j=0; j<${#OPTIONS[@]}; j+=2))
      do
          local name="${OPTIONS[$j]}"
          local desc="${OPTIONS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done
      __subrepo_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _subrepo subrepo

