#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_pcorelist() {

    COMPREPLY=()
    local program=pcorelist
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $COMP_CWORD - 1`
    MYWORDS=("${COMP_WORDS[@]:1:$COMP_CWORD}")

    FLAGS=('--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=()
    __pcorelist_handle_options_flags

    case $INDEX in

    0)
        __comp_current_options || return
        __pcorelist_dynamic_comp 'commands' 'diff'$'\t''Show diff between two Perl versions'$'\n''features'$'\t''List features with perl versions'$'\n''help'$'\t''Show command help'$'\n''module'$'\t''Show for which perl version the module was first released'$'\n''modules'$'\t''List all modules'$'\n''perl'$'\t''Perl Versions'

    ;;
    *)
    # subcmds
    case ${MYWORDS[0]} in
      _complete)
        FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
        OPTIONS+=('--name' 'name of the program')
        __pcorelist_handle_options_flags
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
        __pcorelist_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
      diff)
        FLAGS+=('--added' 'Show only added modules' '--removed' 'Show only removed modules')
        OPTIONS+=()
        __pcorelist_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _pcorelist_diff_param_perl1_completion
          ;;
          2)
              __comp_current_options || return
                _pcorelist_diff_param_perl2_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      features)
        FLAGS+=('--raw' 'List only feature names')
        OPTIONS+=()
        __pcorelist_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _pcorelist_features_param_feature_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      help)
        FLAGS+=('--all' '')
        OPTIONS+=()
        __pcorelist_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __pcorelist_dynamic_comp 'commands' 'diff'$'\n''features'$'\n''module'$'\n''modules'$'\n''perl'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          _complete)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          _pod)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          diff)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          features)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          module)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          modules)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          perl)
            FLAGS+=()
            OPTIONS+=()
            __pcorelist_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
        esac

        ;;
        esac
      ;;
      module)
        FLAGS+=('--all' 'Show all perl and module versions' '-a' 'Show all perl and module versions' '--date' 'Show by date' '-d' 'Show by date')
        OPTIONS+=('--perl' 'Show by Perl Version' '-p' 'Show by Perl Version')
        __pcorelist_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
                _pcorelist_module_param_module_completion
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --perl|-p)
                _pcorelist_module_option_perl_completion
              ;;

            esac
            ;;
        esac
      ;;
      modules)
        FLAGS+=()
        OPTIONS+=()
        __pcorelist_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
      perl)
        FLAGS+=('--raw' 'Show raw output without header' '-r' 'Show raw output without header' '--release' 'Show perl releases with dates')
        OPTIONS+=()
        __pcorelist_handle_options_flags
          case $INDEX in
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
    esac

    ;;
    esac

}

_pcorelist_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) # Remove ' -- ' and everything after
        COMPREPLY="$(echo -e "$COMPREPLY" | sed -e 's/[[:space:]]*$//')"
    fi
}

_pcorelist_diff_param_perl1_completion() {
    local param_perl1=`$program 'perl' '--raw'`
    _pcorelist_compreply "$param_perl1"
}
_pcorelist_diff_param_perl2_completion() {
    local param_perl2=`$program 'perl' '--raw'`
    _pcorelist_compreply "$param_perl2"
}
_pcorelist_features_param_feature_completion() {
    local param_feature=`$program 'features' '--raw'`
    _pcorelist_compreply "$param_feature"
}
_pcorelist_module_param_module_completion() {
    local param_module=`$program 'modules'`
    _pcorelist_compreply "$param_module"
}
_pcorelist_module_option_perl_completion() {
    local param_perl=`$program 'perl' '--raw'`
    _pcorelist_compreply "$param_perl"
}

__pcorelist_dynamic_comp() {
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
    _pcorelist_compreply "$comp"
}

function __pcorelist_handle_options() {
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

function __pcorelist_handle_flags() {
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

__pcorelist_handle_options_flags() {
    __pcorelist_handle_options
    __pcorelist_handle_flags
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
      __pcorelist_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _pcorelist pcorelist

