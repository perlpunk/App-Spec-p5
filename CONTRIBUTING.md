# How to contribute

This module uses Dist::Zilla for creating releases, but you should
be able to develop and test it without Dist::Zilla.

## Commits

I try to follow these guidelines:

* Commit messages
  * Short commit message headline (if possible, up to 60 characters)
  * Blank line before message body
  * Message should be like: "Add foo ...", "Fix ..."
* Git workflow
  * I rebase every branch before merging it with --no-ff
  * I avoid merging master into branches and try to rebase always
  * User branches might be heavily rebased/reordered/squashed because
    I like a clean history


## Code

* No Tabs please
* No trailing whitespaces please
* Look at existing code for formatting ;-)

## Testing

    prove -lr t xt

There is also a make target which re-runs the tests if a file has changed:

    make -f Makefile.dev watch-test

You can check coverage with

    make -f Makefile.dev cover

## Contact

Email: tinita at cpan.org
IRC: tinita on freenode and irc.perl.org

Chances are good that contacting me on IRC is the fastest way.
