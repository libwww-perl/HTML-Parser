use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 2;


my $p;
$p = HTML::Parser->new(
    start_h => [
        sub {
            undef $p;
        }
    ],
);

$p->parse(q(<foo>));

pass 'no SEGV';

# The flush that eof() performs runs handlers too, so it needs the same
# guard on the parser object that parse() has.
my $q;
$q = HTML::Parser->new(
    text_h => [
        sub {
            undef $q;
        },
        "text"
    ],
);

$q->parse(q(<title>x));
$q->eof;

pass 'no SEGV from eof';
