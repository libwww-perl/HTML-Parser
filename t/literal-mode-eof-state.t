use strict;
use warnings;

# Flushing the bytes left after an unclosed literal element at EOF must not
# consume a marked section terminator. Swallowing "]]>" leaves the marked
# section stack unpopped, which silently disables the parser for every later
# document.

use HTML::Parser ();
use Test::More;

my $probe = HTML::Parser->new(api_version => 3);
my $error;
{
    local $@;
    $error = $@ || "Error" unless eval {
        $probe->marked_sections(1);
        1;
    };
}

plan skip_all => $error if $error;
plan tests    => 3;

sub parse_events {
    my ($parser, $html) = @_;
    my @events;
    $parser->handler(start => sub { push @events, "start=$_[0]" }, "tagname");
    $parser->handler(text  => sub { push @events, "text=$_[0]" },  "text");
    $parser->handler(end   => sub { push @events, "end=$_[0]" },   "tagname");
    $parser->parse($html);
    $parser->eof;
    \@events;
}

my $parser = HTML::Parser->new(api_version => 3);
$parser->marked_sections(1);

parse_events($parser, "<![IGNORE[<script>x]]>");

is_deeply(
    parse_events($parser, "<p>hi</p>"),
    ["start=p", "text=hi", "end=p"],
    "parser still reports events after an ignored unclosed literal element",
);

is_deeply(
    parse_events($parser, "<b>again</b>"),
    ["start=b", "text=again", "end=b"],
    "parser is not left permanently disabled",
);

my $included = HTML::Parser->new(api_version => 3);
$included->marked_sections(1);
my $events = parse_events($included, "<![INCLUDE[<script>x]]>");
is(
    join("", map { m|^text=(.*)|s ? $1 : () } @$events),
    "x", "marked section terminator is not swallowed into the element text",
);
