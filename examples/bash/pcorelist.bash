#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_pcorelist() {

    COMPREPLY=()
    local program=pcorelist
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _pcorelist_compreply '_complete -- Generate self completion'$'\n''diff      -- Show diff between two Perl versions'$'\n''features  -- List features with perl versions'$'\n''help      -- Show command help'$'\n''module    -- Show for which perl version the module was first released'$'\n''modules   -- List all modules'$'\n''perl      -- Perl Versions'

    ;;
    *)
    # subcmds
    case ${COMP_WORDS[1]} in
      _complete)
        case $COMP_CWORD in
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --name)
          ;;
          --zsh)
          ;;
          --bash)
          ;;

          *)
            _pcorelist_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--name -- name of the program'"$'\n'"'--zsh  -- for zsh'"$'\n'"'--bash -- for bash'"
          ;;
        esac
        ;;
        esac
      ;;
      diff)
        case $COMP_CWORD in
        2)
                _pcorelist_diff_param_perl1_completion
        ;;
        3)
                _pcorelist_diff_param_perl2_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --added)
          ;;
          --removed)
          ;;

          *)
            _pcorelist_compreply "'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"$'\n'"'--added   -- Show only added modules'"$'\n'"'--removed -- Show only removed modules'"
          ;;
        esac
        ;;
        esac
      ;;
      features)
        case $COMP_CWORD in
        2)
                _pcorelist_features_param_feature_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --raw)
          ;;

          *)
            _pcorelist_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--raw  -- List only feature names'"
          ;;
        esac
        ;;
        esac
      ;;
      help)
        case $COMP_CWORD in

        2)
            _pcorelist_compreply '_complete'$'\n''diff     '$'\n''features '$'\n''module   '$'\n''modules  '$'\n''perl     '

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          _complete)
          ;;
          diff)
          ;;
          features)
          ;;
          module)
          ;;
          modules)
          ;;
          perl)
          ;;
        esac

        ;;
        esac
      ;;
      module)
        case $COMP_CWORD in
        2)
                _pcorelist_module_param_module_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all|-a)
          ;;
          --date|-d)
          ;;
          --perl|-p)
            _pcorelist_module_option_perl_completion
          ;;

          *)
            _pcorelist_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--all  -- Show all perl and module versions'"$'\n'"'-a     -- Show all perl and module versions'"$'\n'"'--date -- Show by date'"$'\n'"'-d     -- Show by date'"$'\n'"'--perl -- Show by Perl Version'"$'\n'"'-p     -- Show by Perl Version'"
          ;;
        esac
        ;;
        esac
      ;;
      modules)
      ;;
      perl)
        case $COMP_CWORD in
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --raw|-r)
          ;;
          --release)
          ;;

          *)
            _pcorelist_compreply "'--help    -- Show command help'"$'\n'"'-h        -- Show command help'"$'\n'"'--raw     -- Show raw output without header'"$'\n'"'-r        -- Show raw output without header'"$'\n'"'--release -- Show perl releases with dates'"
          ;;
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
        COMPREPLY=( ${COMPREPLY[0]%%  *-- *} ) # Remove ' -- ' and everything after
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


complete -o default -F _pcorelist pcorelist

