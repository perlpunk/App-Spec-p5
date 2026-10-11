# fish completion for subrepo
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "subrepo completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __subrepo_optspecs PATH...: argparse optspecs of the options declared by PATH
function __subrepo_optspecs
    switch "$argv"
        case ''
            string join \n -- h help
        case branch
            string join \n -- all
        case clean
            string join \n -- all
        case clone
            string join \n -- b= branch= f force
        case fetch
            string join \n -- all
        case init
            string join \n -- b= branch= r= remote=
        case pull
            string join \n -- all b= branch= r= remote= u= update=
        case push
            string join \n -- all b= branch= r= remote= u= update=
        case status
            string join \n -- q= quiet=
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __subrepo_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__subrepo_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" ''; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __subrepo_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __subrepo_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__subrepo_words)
    set -l np (count $path)
    if test $np -gt 0
        test "$words[1..$np]" = "$path"; or return 1
    end
    set -l rest (math (count $words) - $np)
    if string match -q '*+' -- $n
        test $rest -ge (string trim -r -c + -- $n)
    else
        test $rest -eq $n
    end
end

# __subrepo_prefix PATH...: true if the words start with PATH
function __subrepo_prefix
    __subrepo_using $argv 0+
end

function __subrepo_branch_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_clean_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_commit_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_fetch_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_pull_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_push_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

function __subrepo_status_param_subrepo_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] status '--quiet'
end

complete -c subrepo -f
complete -c subrepo -n '__subrepo_using 0' -f -a branch -d 'Create a branch with local subrepo commits since last pull.'
complete -c subrepo -n '__subrepo_using 0' -f -a clean -d 'Remove artifacts created by `fetch` and `branch` commands.'
complete -c subrepo -n '__subrepo_using 0' -f -a clone -d 'Add a repository as a subrepo in a subdir of your repository.'
complete -c subrepo -n '__subrepo_using 0' -f -a commit -d 'Add subrepo branch to current history as a single commit.'
complete -c subrepo -n '__subrepo_using 0' -f -a fetch -d 'Fetch the remote/upstream content for a subrepo.'
complete -c subrepo -n '__subrepo_using 0' -f -a help -d 'Same as `git help subrepo`'
complete -c subrepo -n '__subrepo_using 0' -f -a init -d 'Turn an existing subdirectory into a subrepo.'
complete -c subrepo -n '__subrepo_using 0' -f -a pull -d 'Update the subrepo subdir with the latest upstream changes.'
complete -c subrepo -n '__subrepo_using 0' -f -a push -d 'Push a properly merged subrepo branch back upstream.'
complete -c subrepo -n '__subrepo_using 0' -f -a status -d 'Get the status of a subrepo.'
complete -c subrepo -n '__subrepo_using 0' -f -a version -d 'display version information about git-subrepo'
complete -c subrepo -n __subrepo_prefix -l help -s h -d 'Show command help'
complete -c subrepo -n '__subrepo_using branch 0' -f -a '(__subrepo_branch_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix branch' -l all -d 'All subrepos'
complete -c subrepo -n '__subrepo_using clean 0' -f -a '(__subrepo_clean_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix clean' -l all -d 'All subrepos'
complete -c subrepo -n '__subrepo_using clone 1' -F
complete -c subrepo -n '__subrepo_prefix clone' -l branch -s b -d 'Upstream branch' -x
complete -c subrepo -n '__subrepo_prefix clone' -l force -s f -d 'reclone (completely replace) an existing subdir.'
complete -c subrepo -n '__subrepo_using commit 0' -f -a '(__subrepo_commit_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_using fetch 0' -f -a '(__subrepo_fetch_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix fetch' -l all -d 'All subrepos'
complete -c subrepo -n '__subrepo_using init 0' -F
complete -c subrepo -n '__subrepo_prefix init' -l remote -s r -d 'Specify remote repository' -x
complete -c subrepo -n '__subrepo_prefix init' -l branch -s b -d 'Upstream branch' -x
complete -c subrepo -n '__subrepo_using pull 0' -f -a '(__subrepo_pull_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix pull' -l all -d 'All subrepos'
complete -c subrepo -n '__subrepo_prefix pull' -l branch -s b -d 'Upstream branch' -x
complete -c subrepo -n '__subrepo_prefix pull' -l remote -s r -d 'Specify remote repository' -x
complete -c subrepo -n '__subrepo_prefix pull' -l update -s u -d update -x
complete -c subrepo -n '__subrepo_using push 0' -f -a '(__subrepo_push_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix push' -l all -d 'All subrepos'
complete -c subrepo -n '__subrepo_prefix push' -l branch -s b -d 'Upstream branch' -x
complete -c subrepo -n '__subrepo_prefix push' -l remote -s r -d 'Specify remote repository' -x
complete -c subrepo -n '__subrepo_prefix push' -l update -s u -d update -x
complete -c subrepo -n '__subrepo_using status 0' -f -a '(__subrepo_status_param_subrepo_completion)' -d Subrepo
complete -c subrepo -n '__subrepo_prefix status' -l quiet -s q -d 'Just print names' -x

