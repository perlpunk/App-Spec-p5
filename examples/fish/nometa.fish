# fish completion for nometa
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "nometa completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __nometa_optspecs PATH...: argparse optspecs of the options declared by PATH
function __nometa_optspecs
    switch "$argv"
        case ''
            string join \n -- h help
        case help
            string join \n -- all
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __nometa_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__nometa_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" '' help; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __nometa_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __nometa_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__nometa_words)
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

# __nometa_prefix PATH...: true if the words start with PATH
function __nometa_prefix
    __nometa_using $argv 0+
end

complete -c nometa -f
complete -c nometa -n '__nometa_using 0' -f -a foo -d 'Test command'
complete -c nometa -n '__nometa_using 0' -f -a help -d 'Show command help'
complete -c nometa -n '__nometa_using 0' -f -a longsubcommand -d 'A subcommand with a very long summary split over multiple lines'
complete -c nometa -n __nometa_prefix -l help -s h -d 'Show command help'
complete -c nometa -n '__nometa_using foo 0' -f -a 'a b c'
complete -c nometa -n '__nometa_using help 0' -f -a foo
complete -c nometa -n '__nometa_using help 0' -f -a longsubcommand
complete -c nometa -n '__nometa_prefix help' -l all

