#!/usr/bin/env bash

# Generated with perl module App::Spec v0.000

_myapp() {

    COMPREPLY=()
    local program=myapp
    local cur prev words cword
    _init_completion -n : || return
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $cword - 1`
    MYWORDS=("${words[@]:1:$cword}")

    FLAGS=('--verbose' 'be verbose' '-v' 'be verbose' '--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=('--format' 'Format output')
    __myapp_handle_options_flags

    case $INDEX in

    0)
        __comp_current_options || return
        __myapp_dynamic_comp 'commands' 'config'$'\t''configuration'$'\n''convert'$'\t''Various unit conversions'$'\n''cook'$'\t''Cook something'$'\n''data'$'\t''output some data'$'\n''help'$'\t''Show command help'$'\n''palindrome'$'\t''Check if a string is a palindrome'$'\n''weather'$'\t''Weather'

    ;;
    *)
    # subcmds
    case ${MYWORDS[0]} in
      _meta)
        __myapp_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __myapp_dynamic_comp 'commands' 'completion'$'\t''Shell completion functions'$'\n''pod'$'\t''Pod documentation'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          completion)
            __myapp_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __myapp_dynamic_comp 'commands' 'generate'$'\t''Generate self completion'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              generate)
                FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
                OPTIONS+=('--name' 'name of the program (optional, override name in spec)')
                __myapp_handle_options_flags
                case ${MYWORDS[$INDEX-1]} in
                  --format)
                    _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
                    return
                  ;;
                  --name)
                  ;;

                esac
                case $INDEX in

                *)
                    __comp_current_options || return
                ;;
                esac
              ;;
            esac

            ;;
            esac
          ;;
          pod)
            __myapp_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __myapp_dynamic_comp 'commands' 'generate'$'\t''Generate self pod'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              generate)
                __myapp_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      config)
        OPTIONS+=('--set' 'key=value pair(s)')
        __myapp_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --format)
            _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
            return
          ;;
          --set)
          ;;

        esac
        case $INDEX in

        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      convert)
        __myapp_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --format)
            _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
            return
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _myapp_convert_param_type_completion
          ;;
          2)
              __comp_current_options || return
                _myapp_convert_param_source_completion
          ;;
          3)
              __comp_current_options || return
          ;;
          4)
              __comp_current_options || return
                _myapp_convert_param_target_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      cook)
        FLAGS+=('--sugar' 'add sugar' '-s' 'add sugar')
        OPTIONS+=('--with' 'Drink with ...')
        __myapp_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --format)
            _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
            return
          ;;
          --with)
            _myapp_compreply "almond\\\\ milk" "soy\\\\ milk" "oat\\\\ milk" "spelt\\\\ milk" "cow\\\\ milk"
            return
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _myapp_compreply "tea" "coffee"
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      data)
        OPTIONS+=('--item' '')
        __myapp_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --format)
            _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
            return
          ;;
          --item)
            _myapp_compreply "hash" "table"
            return
          ;;

        esac
        case $INDEX in

        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      help)
        FLAGS+=('--all' '')
        __myapp_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __myapp_dynamic_comp 'commands' 'config'$'\n''convert'$'\n''cook'$'\n''data'$'\n''palindrome'$'\n''weather'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          _meta)
            __myapp_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __myapp_dynamic_comp 'commands' 'completion'$'\n''pod'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              completion)
                __myapp_handle_options_flags
                case $INDEX in

                3)
                    __comp_current_options || return
                    __myapp_dynamic_comp 'commands' 'generate'

                ;;
                *)
                # subcmds
                case ${MYWORDS[3]} in
                  generate)
                    __myapp_handle_options_flags
                    __comp_current_options true || return # no subcmds, no params/opts
                  ;;
                esac

                ;;
                esac
              ;;
              pod)
                __myapp_handle_options_flags
                case $INDEX in

                3)
                    __comp_current_options || return
                    __myapp_dynamic_comp 'commands' 'generate'

                ;;
                *)
                # subcmds
                case ${MYWORDS[3]} in
                  generate)
                    __myapp_handle_options_flags
                    __comp_current_options true || return # no subcmds, no params/opts
                  ;;
                esac

                ;;
                esac
              ;;
            esac

            ;;
            esac
          ;;
          config)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          convert)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          cook)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          data)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          palindrome)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          weather)
            __myapp_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __myapp_dynamic_comp 'commands' 'cities'$'\n''countries'$'\n''show'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              cities)
                __myapp_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              countries)
                __myapp_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              show)
                __myapp_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
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
        __myapp_handle_options_flags
        case ${MYWORDS[$INDEX-1]} in
          --format)
            _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
            return
          ;;

        esac
        case $INDEX in
          1)
              __comp_current_options || return
                _myapp_palindrome_param_string_completion
          ;;


        *)
            __comp_current_options || return
        ;;
        esac
      ;;
      weather)
        __myapp_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __myapp_dynamic_comp 'commands' 'cities'$'\t''show list of cities'$'\n''countries'$'\t''show list of countries'$'\n''show'$'\t''Show Weather forecast'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          cities)
            OPTIONS+=('--country' 'country name(s)' '-c' 'country name(s)')
            __myapp_handle_options_flags
            case ${MYWORDS[$INDEX-1]} in
              --format)
                _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
                return
              ;;
              --country|-c)
                _myapp_weather_cities_option_country_completion
              ;;

            esac
            case $INDEX in

            *)
                __comp_current_options || return
            ;;
            esac
          ;;
          countries)
            __myapp_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          show)
            FLAGS+=('--temperature' 'show temperature' '-T' 'show temperature' '--celsius' 'show temperature in celsius' '-C' 'show temperature in celsius' '--fahrenheit' 'show temperature in fahrenheit' '-F' 'show temperature in fahrenheit')
            __myapp_handle_options_flags
            case ${MYWORDS[$INDEX-1]} in
              --format)
                _myapp_compreply "JSON" "YAML" "Table" "Data::Dumper" "Data::Dump"
                return
              ;;

            esac
            case $INDEX in
              2)
                  __comp_current_options || return
                    _myapp_weather_show_param_country_completion
              ;;
              3)
                  __comp_current_options || return
                    _myapp_weather_show_param_city_completion
              ;;


            *)
                __comp_current_options || return
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

_myapp_convert_param_type_completion() {
    local __dynamic_completion
    __dynamic_completion=$(PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='type' ${words[@]})
    __myapp_dynamic_comp 'type' "$__dynamic_completion"
}
_myapp_convert_param_source_completion() {
    local __dynamic_completion
    __dynamic_completion=$(PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='source' ${words[@]})
    __myapp_dynamic_comp 'source' "$__dynamic_completion"
}
_myapp_convert_param_target_completion() {
    local __dynamic_completion
    __dynamic_completion=$(PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='target' ${words[@]})
    __myapp_dynamic_comp 'target' "$__dynamic_completion"
}
_myapp_palindrome_param_string_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_string="$(cat /usr/share/dict/words | perl -nle'print if $_ eq reverse $_')"
    _myapp_compreply "$param_string"
}
_myapp_weather_cities_option_country_completion() {
    local CURRENT_WORD="${words[$cword]}"
    local param_country="$($program 'weather' 'countries')"
    _myapp_compreply "$param_country"
}
_myapp_weather_show_param_country_completion() {
    local __dynamic_completion
    __dynamic_completion=$(PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='country' ${words[@]})
    __myapp_dynamic_comp 'country' "$__dynamic_completion"
}
_myapp_weather_show_param_city_completion() {
    local __dynamic_completion
    __dynamic_completion=$(PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='city' ${words[@]})
    __myapp_dynamic_comp 'city' "$__dynamic_completion"
}

__myapp_dynamic_comp() {
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
    _myapp_compreply ${comp[@]}
}

function __myapp_handle_options() {
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

function __myapp_handle_flags() {
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

__myapp_handle_options_flags() {
    __myapp_handle_options
    __myapp_handle_flags
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
      __myapp_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _myapp myapp

