#!bash

# Generated with perl module App::Spec v0.000

_mysimpleapp() {

    COMPREPLY=()
    local program=mysimpleapp
    local cur prev words cword
    _init_completion -n : || return
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $cword - 1`
    MYWORDS=("${words[@]:1:$cword}")

    FLAGS=('--verbose' 'be verbose' '-v' 'be verbose' '--wc' 'word count' '--lc' 'line count' '--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=('--with' 'with ...' '--file1' 'existing file' '--file2' 'possible file' '--dir1' 'existing dir' '--dir2' 'possible dir')
    __mysimpleapp_handle_options_flags

    case ${MYWORDS[$INDEX-1]} in
      --with)
        _mysimpleapp_compreply "ab" "cd" "ef"
        return
      ;;
      --file1)
        compopt -o filenames
        return
      ;;
      --file2)
        compopt -o filenames
        return
      ;;
      --dir1)
        compopt -o dirnames
        return
      ;;
      --dir2)
        compopt -o dirnames
        return
      ;;

    esac
    case $INDEX in
      0)
          __comp_current_options || return
            _mysimpleapp_compreply "dist.ini" "Makefile.PL" "Changes"
      ;;
      1)
          __comp_current_options || return
            _mysimpleapp_compreply "a" "b" "c"
      ;;


    *)
        __comp_current_options || return
    ;;
    esac

}

_mysimpleapp_compreply() {
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


__mysimpleapp_dynamic_comp() {
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
    _mysimpleapp_compreply ${comp[@]}
}

function __mysimpleapp_handle_options() {
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

function __mysimpleapp_handle_flags() {
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

__mysimpleapp_handle_options_flags() {
    __mysimpleapp_handle_options
    __mysimpleapp_handle_flags
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
      __mysimpleapp_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _mysimpleapp mysimpleapp

