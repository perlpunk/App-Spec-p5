# fish completion for pcorelist
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "pcorelist completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __pcorelist_optspecs PATH...: argparse optspecs of the options declared by PATH
function __pcorelist_optspecs
    switch "$argv"
        case ''
            string join \n -- h help
        case '_meta completion generate'
            string join \n -- bash fish name= zsh
        case diff
            string join \n -- added removed
        case features
            string join \n -- raw
        case help
            string join \n -- all
        case module
            string join \n -- a all d date p= perl=
        case perl
            string join \n -- r raw release
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __pcorelist_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__pcorelist_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" '' _meta '_meta completion' '_meta pod' help 'help _meta' 'help _meta completion' 'help _meta pod'; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __pcorelist_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __pcorelist_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__pcorelist_words)
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

# __pcorelist_prefix PATH...: true if the words start with PATH
function __pcorelist_prefix
    __pcorelist_using $argv 0+
end

function __pcorelist_diff_param_perl1_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] perl '--raw'
end

function __pcorelist_diff_param_perl2_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] perl '--raw'
end

function __pcorelist_features_param_feature_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] features '--raw'
end

function __pcorelist_module_param_module_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] modules
end

function __pcorelist_module_option_perl_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] perl '--raw'
end

complete -c pcorelist -f
complete -c pcorelist -n '__pcorelist_using 0' -f -a diff -d 'Show diff between two Perl versions'
complete -c pcorelist -n '__pcorelist_using 0' -f -a features -d 'List features with perl versions'
complete -c pcorelist -n '__pcorelist_using 0' -f -a help -d 'Show command help'
complete -c pcorelist -n '__pcorelist_using 0' -f -a module -d 'Show for which perl version the module was first released'
complete -c pcorelist -n '__pcorelist_using 0' -f -a modules -d 'List all modules'
complete -c pcorelist -n '__pcorelist_using 0' -f -a perl -d 'Perl Versions'
complete -c pcorelist -n __pcorelist_prefix -l help -s h -d 'Show command help'
complete -c pcorelist -n '__pcorelist_using _meta 0' -f -a completion -d 'Shell completion functions'
complete -c pcorelist -n '__pcorelist_using _meta 0' -f -a pod -d 'Pod documentation'
complete -c pcorelist -n '__pcorelist_using _meta completion 0' -f -a generate -d 'Generate self completion'
complete -c pcorelist -n '__pcorelist_prefix _meta completion generate' -l name -d 'name of the program (optional, override name in spec)' -x
complete -c pcorelist -n '__pcorelist_prefix _meta completion generate' -l zsh -d 'for zsh'
complete -c pcorelist -n '__pcorelist_prefix _meta completion generate' -l bash -d 'for bash'
complete -c pcorelist -n '__pcorelist_prefix _meta completion generate' -l fish -d 'for fish (>= 4.0)'
complete -c pcorelist -n '__pcorelist_using _meta pod 0' -f -a generate -d 'Generate self pod'
complete -c pcorelist -n '__pcorelist_using diff 0' -f -a '(__pcorelist_diff_param_perl1_completion)' -d 'Perl version 1'
complete -c pcorelist -n '__pcorelist_using diff 1' -f -a '(__pcorelist_diff_param_perl2_completion)' -d 'Perl version 2'
complete -c pcorelist -n '__pcorelist_prefix diff' -l added -d 'Show only added modules'
complete -c pcorelist -n '__pcorelist_prefix diff' -l removed -d 'Show only removed modules'
complete -c pcorelist -n '__pcorelist_using features 0' -f -a '(__pcorelist_features_param_feature_completion)' -d 'feature name'
complete -c pcorelist -n '__pcorelist_prefix features' -l raw -d 'List only feature names'
complete -c pcorelist -n '__pcorelist_using help 0' -f -a diff
complete -c pcorelist -n '__pcorelist_using help 0' -f -a features
complete -c pcorelist -n '__pcorelist_using help 0' -f -a module
complete -c pcorelist -n '__pcorelist_using help 0' -f -a modules
complete -c pcorelist -n '__pcorelist_using help 0' -f -a perl
complete -c pcorelist -n '__pcorelist_prefix help' -l all
complete -c pcorelist -n '__pcorelist_using help _meta 0' -f -a completion
complete -c pcorelist -n '__pcorelist_using help _meta 0' -f -a pod
complete -c pcorelist -n '__pcorelist_using help _meta completion 0' -f -a generate
complete -c pcorelist -n '__pcorelist_using help _meta pod 0' -f -a generate
complete -c pcorelist -n '__pcorelist_using module 0' -f -a '(__pcorelist_module_param_module_completion)' -d 'Module name'
complete -c pcorelist -n '__pcorelist_prefix module' -l all -s a -d 'Show all perl and module versions'
complete -c pcorelist -n '__pcorelist_prefix module' -l date -s d -d 'Show by date'
complete -c pcorelist -n '__pcorelist_prefix module' -l perl -s p -d 'Show by Perl Version' -r -f -a '(__pcorelist_module_option_perl_completion)'
complete -c pcorelist -n '__pcorelist_prefix perl' -l raw -s r -d 'Show raw output without header'
complete -c pcorelist -n '__pcorelist_prefix perl' -l release -d 'Show perl releases with dates'

