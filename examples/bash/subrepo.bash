#!bash

# Generated with perl module App::Spec v0.000

_subrepo() {

    COMPREPLY=()
    local program=subrepo
    local cur prev words cword
    _init_completion -n : || return
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $cword - 1`
    MYWORDS=("${words[@]:1:$cword}")

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
      branch)
        FLAGS+=('--all' 'All subrepos')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_branch_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      clean)
        FLAGS+=('--all' 'All subrepos')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_clean_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      clone)
        FLAGS+=('--force' 'reclone (completely replace) an existing subdir.' '-f' 'reclone (completely replace) an existing subdir.')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --branch|-b)
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
          ;;
          2)
              __comp_current_options || return
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      commit)
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_commit_param_subrepo_completion
          ;;
          2)
              __comp_current_options || return
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      fetch)
        FLAGS+=('--all' 'All subrepos')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_fetch_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      help)
        __subrepo_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
      init)
        OPTIONS+=('--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--branch' 'Upstream branch' '-b' 'Upstream branch')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --remote|-r)
          ;;
          --branch|-b)
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      pull)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch' '--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--update' 'update' '-u' 'update')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --branch|-b)
          ;;
          --remote|-r)
          ;;
          --update|-u)
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_pull_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      push)
        FLAGS+=('--all' 'All subrepos')
        OPTIONS+=('--branch' 'Upstream branch' '-b' 'Upstream branch' '--remote' 'Specify remote repository' '-r' 'Specify remote repository' '--update' 'update' '-u' 'update')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --branch|-b)
          ;;
          --remote|-r)
          ;;
          --update|-u)
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_push_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      status)
        OPTIONS+=('--quiet' 'Just print names' '-q' 'Just print names')
        __subrepo_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --quiet|-q)
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _subrepo_status_param_subrepo_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      version)
        __subrepo_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
    esac

    ;;
    esac

}

_subrepo_compreply() {
    local prefix=""
    cur="$(printf '%q' "$cur")"
    IFS=$'\n' COMPREPLY=($(compgen -P "$prefix" -W "$*" -- "$cur"))
    __ltrim_colon_completions "$prefix$cur"

    # http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( "${COMPREPLY[0]%% -- *}" ) # Remove ' -- ' and everything after
        COMPREPLY=( "${COMPREPLY[0]%%+( )}" ) # Remove trailing spaces
    fi
}

_subrepo_branch_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_clean_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_commit_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_fetch_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_pull_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_push_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}
_subrepo_status_param_subrepo_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_subrepo="$($program 'status' '--quiet')"
    _subrepo_compreply "$param_subrepo"
}

__subrepo_dynamic_comp() {
    local argname="$1"
    local arg="$2"
    local name desc cols desclength formatted
    local comp=()
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
            formatted=`printf "%-*s -- %-*s" "$max" "$name" "$desclength" "$desc"`
            comp+=("$formatted")
        else
            comp+=("'$name'")
        fi
    done <<< "$arg"
    _subrepo_compreply ${comp[@]}
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

