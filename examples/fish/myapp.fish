# fish completion for myapp
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "myapp completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __myapp_optspecs PATH...: argparse optspecs of the options declared by PATH
function __myapp_optspecs
    switch "$argv"
        case ''
            string join \n -- format= h help v verbose
        case '_meta completion generate'
            string join \n -- bash fish name= zsh
        case config
            string join \n -- set=
        case cook
            string join \n -- s sugar with=
        case data
            string join \n -- item=
        case help
            string join \n -- all
        case 'weather cities'
            string join \n -- c= country=
        case 'weather show'
            string join \n -- C F T celsius fahrenheit temperature
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __myapp_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__myapp_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" '' _meta '_meta completion' '_meta pod' help 'help _meta' 'help _meta completion' 'help _meta pod' 'help weather' weather; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __myapp_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __myapp_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__myapp_words)
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

# __myapp_prefix PATH...: true if the words start with PATH
function __myapp_prefix
    __myapp_using $argv 0+
end

# dynamic completion via App::Spec::Run, prints "value<TAB>description" lines
function __myapp_dynamic
    set -l cmd (commandline -xpc) (commandline -ct)
    PERL5_APPSPECRUN_SHELL=fish PERL5_APPSPECRUN_COMPLETION_PARAMETER=$argv[1] $cmd
end

function __myapp_palindrome_param_string_completion
    set -l words (commandline -xpc) (commandline -ct)
    CURRENT_WORD=$words[-1] bash -c 'cat /usr/share/dict/words | perl -nle\'print if $_ eq reverse $_\'
'
end

function __myapp_weather_cities_option_country_completion
    set -l words (commandline -xpc) (commandline -ct)
    $words[1] weather countries
end

complete -c myapp -f
complete -c myapp -n '__myapp_using 0' -f -a config -d configuration
complete -c myapp -n '__myapp_using 0' -f -a convert -d 'Various unit conversions'
complete -c myapp -n '__myapp_using 0' -f -a cook -d 'Cook something'
complete -c myapp -n '__myapp_using 0' -f -a data -d 'output some data'
complete -c myapp -n '__myapp_using 0' -f -a help -d 'Show command help'
complete -c myapp -n '__myapp_using 0' -f -a palindrome -d 'Check if a string is a palindrome'
complete -c myapp -n '__myapp_using 0' -f -a weather -d Weather
complete -c myapp -n __myapp_prefix -l verbose -s v -d 'be verbose'
complete -c myapp -n __myapp_prefix -l help -s h -d 'Show command help'
complete -c myapp -n __myapp_prefix -l format -d 'Format output' -r -f -a 'JSON YAML Table Data::Dumper Data::Dump'
complete -c myapp -n '__myapp_using _meta 0' -f -a completion -d 'Shell completion functions'
complete -c myapp -n '__myapp_using _meta 0' -f -a pod -d 'Pod documentation'
complete -c myapp -n '__myapp_using _meta completion 0' -f -a generate -d 'Generate self completion'
complete -c myapp -n '__myapp_prefix _meta completion generate' -l name -d 'name of the program (optional, override name in spec)' -x
complete -c myapp -n '__myapp_prefix _meta completion generate' -l zsh -d 'for zsh'
complete -c myapp -n '__myapp_prefix _meta completion generate' -l bash -d 'for bash'
complete -c myapp -n '__myapp_prefix _meta completion generate' -l fish -d 'for fish (>= 4.0)'
complete -c myapp -n '__myapp_using _meta pod 0' -f -a generate -d 'Generate self pod'
complete -c myapp -n '__myapp_prefix config' -l set -d 'key=value pair(s)' -x
complete -c myapp -n '__myapp_using convert 0' -f -a '(__myapp_dynamic type)' -d 'The type of unit to convert'
complete -c myapp -n '__myapp_using convert 1' -f -a '(__myapp_dynamic source)' -d 'The source unit to convert from'
complete -c myapp -n '__myapp_using convert 3+' -f -a '(__myapp_dynamic target)' -d 'The target unit'
complete -c myapp -n '__myapp_using cook 0' -f -a 'tea coffee' -d 'What to drink'
complete -c myapp -n '__myapp_prefix cook' -l with -d 'Drink with ...' -r -f -a "'almond milk' 'soy milk' 'oat milk' 'spelt milk' 'cow milk'"
complete -c myapp -n '__myapp_prefix cook' -l sugar -s s -d 'add sugar'
complete -c myapp -n '__myapp_prefix data' -l item -r -f -a 'hash table'
complete -c myapp -n '__myapp_using help 0' -f -a config
complete -c myapp -n '__myapp_using help 0' -f -a convert
complete -c myapp -n '__myapp_using help 0' -f -a cook
complete -c myapp -n '__myapp_using help 0' -f -a data
complete -c myapp -n '__myapp_using help 0' -f -a palindrome
complete -c myapp -n '__myapp_using help 0' -f -a weather
complete -c myapp -n '__myapp_prefix help' -l all
complete -c myapp -n '__myapp_using help _meta 0' -f -a completion
complete -c myapp -n '__myapp_using help _meta 0' -f -a pod
complete -c myapp -n '__myapp_using help _meta completion 0' -f -a generate
complete -c myapp -n '__myapp_using help _meta pod 0' -f -a generate
complete -c myapp -n '__myapp_using help weather 0' -f -a cities
complete -c myapp -n '__myapp_using help weather 0' -f -a countries
complete -c myapp -n '__myapp_using help weather 0' -f -a show
complete -c myapp -n '__myapp_using palindrome 0' -f -a '(__myapp_palindrome_param_string_completion)'
complete -c myapp -n '__myapp_using weather 0' -f -a cities -d 'show list of cities'
complete -c myapp -n '__myapp_using weather 0' -f -a countries -d 'show list of countries'
complete -c myapp -n '__myapp_using weather 0' -f -a show -d 'Show Weather forecast'
complete -c myapp -n '__myapp_prefix weather cities' -l country -s c -d 'country name(s)' -r -f -a '(__myapp_weather_cities_option_country_completion)'
complete -c myapp -n '__myapp_using weather show 0' -f -a '(__myapp_dynamic country)' -d 'Specify country'
complete -c myapp -n '__myapp_using weather show 1+' -f -a '(__myapp_dynamic city)' -d 'Specify city or cities'
complete -c myapp -n '__myapp_prefix weather show' -l temperature -s T -d 'show temperature'
complete -c myapp -n '__myapp_prefix weather show' -l celsius -s C -d 'show temperature in celsius'
complete -c myapp -n '__myapp_prefix weather show' -l fahrenheit -s F -d 'show temperature in fahrenheit'

