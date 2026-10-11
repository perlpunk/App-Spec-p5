# fish completion for mysimpleapp
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "mysimpleapp completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __mysimpleapp_optspecs PATH...: argparse optspecs of the options declared by PATH
function __mysimpleapp_optspecs
    switch "$argv"
        case ''
            string join \n -- dir1= dir2= file1= file2= h help lc longoption longoption2= v verbose wc with=
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __mysimpleapp_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__mysimpleapp_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" ; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __mysimpleapp_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __mysimpleapp_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__mysimpleapp_words)
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

# __mysimpleapp_prefix PATH...: true if the words start with PATH
function __mysimpleapp_prefix
    __mysimpleapp_using $argv 0+
end

complete -c mysimpleapp -f
complete -c mysimpleapp -n '__mysimpleapp_using 0' -f -a 'dist.ini Makefile.PL Changes' -d foo
complete -c mysimpleapp -n '__mysimpleapp_using 1' -f -a 'a b c' -d bar
complete -c mysimpleapp -n __mysimpleapp_prefix -l verbose -s v -d 'be verbose'
complete -c mysimpleapp -n __mysimpleapp_prefix -l wc -d 'word count'
complete -c mysimpleapp -n __mysimpleapp_prefix -l lc -d 'line count'
complete -c mysimpleapp -n __mysimpleapp_prefix -l with -d 'with ...' -r -f -a 'ab cd ef'
complete -c mysimpleapp -n __mysimpleapp_prefix -l file1 -d 'existing file' -r -F
complete -c mysimpleapp -n __mysimpleapp_prefix -l file2 -d 'possible file' -r -F
complete -c mysimpleapp -n __mysimpleapp_prefix -l dir1 -d 'existing dir' -r -f -a '(__fish_complete_directories (commandline -ct))'
complete -c mysimpleapp -n __mysimpleapp_prefix -l dir2 -d 'possible dir' -r -f -a '(__fish_complete_directories (commandline -ct))'
complete -c mysimpleapp -n __mysimpleapp_prefix -l longoption -d 'some long option description split over several lines to demonstrate'
complete -c mysimpleapp -n __mysimpleapp_prefix -l longoption2 -d 'some other long option description split over several lines to demonstrate' -x
complete -c mysimpleapp -n __mysimpleapp_prefix -l help -s h -d 'Show command help'

