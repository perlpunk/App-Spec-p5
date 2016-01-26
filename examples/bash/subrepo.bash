#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_subrepo() {

    COMPREPLY=()
    local program=subrepo
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp

    case $COMP_CWORD in

    1)
        _subrepo_compreply '_complete -- Generate self completion'$'\n''branch    -- Create a branch with local subrepo commits since last pull.'$'\n''clean     -- Remove artifacts created by '"'"'fetch'"'"' and '"'"'branch'"'"' commands.'$'\n''clone     -- Add a repository as a subrepo in a subdir of your repository.'$'\n''commit    -- Add subrepo branch to current history as a single commit.'$'\n''fetch     -- Fetch the remote/upstream content for a subrepo.'$'\n''help      -- Same as '"'"'git help subrepo'"'"''$'\n''init      -- Turn an existing subdirectory into a subrepo.'$'\n''pull      -- Update the subrepo subdir with the latest upstream changes.'$'\n''push      -- Push a properly merged subrepo branch back upstream.'$'\n''status    -- Get the status of a subrepo.'$'\n''version   -- display version information about git-subrepo'

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
            _subrepo_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--name -- name of the program'"$'\n'"'--zsh  -- for zsh'"$'\n'"'--bash -- for bash'"
          ;;
        esac
        ;;
        esac
      ;;
      branch)
        case $COMP_CWORD in
        2)
                _subrepo_branch_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all)
          ;;

          *)
            _subrepo_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--all  -- All subrepos'"
          ;;
        esac
        ;;
        esac
      ;;
      clean)
        case $COMP_CWORD in
        2)
                _subrepo_clean_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all)
          ;;

          *)
            _subrepo_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--all  -- All subrepos'"
          ;;
        esac
        ;;
        esac
      ;;
      clone)
        case $COMP_CWORD in
        2)
        ;;
        3)
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --branch|-b)
          ;;
          --force|-f)
          ;;

          *)
            _subrepo_compreply "'--help   -- Show command help'"$'\n'"'-h       -- Show command help'"$'\n'"'--branch -- Upstream branch'"$'\n'"'-b       -- Upstream branch'"$'\n'"'--force  -- reclone (completely replace) an existing subdir.'"$'\n'"'-f       -- reclone (completely replace) an existing subdir.'"
          ;;
        esac
        ;;
        esac
      ;;
      commit)
        case $COMP_CWORD in
        2)
                _subrepo_commit_param_subrepo_completion
        ;;
        3)
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;

          *)
            _subrepo_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"
          ;;
        esac
        ;;
        esac
      ;;
      fetch)
        case $COMP_CWORD in
        2)
                _subrepo_fetch_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all)
          ;;

          *)
            _subrepo_compreply "'--help -- Show command help'"$'\n'"'-h     -- Show command help'"$'\n'"'--all  -- All subrepos'"
          ;;
        esac
        ;;
        esac
      ;;
      help)
        case $COMP_CWORD in

        2)
            _subrepo_compreply '_complete'$'\n''branch   '$'\n''clean    '$'\n''clone    '$'\n''commit   '$'\n''fetch    '$'\n''init     '$'\n''pull     '$'\n''push     '$'\n''status   '$'\n''version  '

        ;;
        *)
        # subcmds
        case ${COMP_WORDS[2]} in
          _complete)
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
        case $COMP_CWORD in
        2)
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --remote|-r)
          ;;
          --branch|-b)
          ;;

          *)
            _subrepo_compreply "'--help   -- Show command help'"$'\n'"'-h       -- Show command help'"$'\n'"'--remote -- Specify remote repository'"$'\n'"'-r       -- Specify remote repository'"$'\n'"'--branch -- Upstream branch'"$'\n'"'-b       -- Upstream branch'"
          ;;
        esac
        ;;
        esac
      ;;
      pull)
        case $COMP_CWORD in
        2)
                _subrepo_pull_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all)
          ;;
          --branch|-b)
          ;;
          --remote|-r)
          ;;
          --update|-u)
          ;;

          *)
            _subrepo_compreply "'--help   -- Show command help'"$'\n'"'-h       -- Show command help'"$'\n'"'--all    -- All subrepos'"$'\n'"'--branch -- Upstream branch'"$'\n'"'-b       -- Upstream branch'"$'\n'"'--remote -- Specify remote repository'"$'\n'"'-r       -- Specify remote repository'"$'\n'"'--update -- update'"$'\n'"'-u       -- update'"
          ;;
        esac
        ;;
        esac
      ;;
      push)
        case $COMP_CWORD in
        2)
                _subrepo_push_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --all)
          ;;
          --branch|-b)
          ;;
          --remote|-r)
          ;;
          --update|-u)
          ;;

          *)
            _subrepo_compreply "'--help   -- Show command help'"$'\n'"'-h       -- Show command help'"$'\n'"'--all    -- All subrepos'"$'\n'"'--branch -- Upstream branch'"$'\n'"'-b       -- Upstream branch'"$'\n'"'--remote -- Specify remote repository'"$'\n'"'-r       -- Specify remote repository'"$'\n'"'--update -- update'"$'\n'"'-u       -- update'"
          ;;
        esac
        ;;
        esac
      ;;
      status)
        case $COMP_CWORD in
        2)
                _subrepo_status_param_subrepo_completion
        ;;
        *)
        case ${COMP_WORDS[$COMP_CWORD-1]} in
          --help|-h)
          ;;
          --quiet|-q)
          ;;

          *)
            _subrepo_compreply "'--help  -- Show command help'"$'\n'"'-h      -- Show command help'"$'\n'"'--quiet -- Just print names'"$'\n'"'-q      -- Just print names'"
          ;;
        esac
        ;;
        esac
      ;;
      version)
      ;;
    esac

    ;;
    esac

}

_subrepo_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%%  *-- *} ) # Remove ' -- ' and everything after
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


complete -o default -F _subrepo subrepo

