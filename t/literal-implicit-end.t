use strict;
use warnings;

# An unclosed script, style or title with nothing after its start tag
# must still get the implicit end event at EOF, exactly as it does when
# trailing bytes are present.

use HTML::Parser ();
use Test::More tests => 6;

sub events {
    my @events;
    my $p = HTML::Parser->new(
        start_h => [sub { push @events, "start=$_[0]" }, "tagname"],
        text_h  => [sub { push @events, "text=$_[0]" },  "text"],
        end_h   => [sub { push @events, "end=$_[0]" },   "tagname"],
    );
    $p->parse($_) for @_;
    $p->eof;
    join "|", @events;
}

for my $el (qw( script style title )) {
    is(events("<$el>"), "start=$el|end=$el",
        "empty unclosed $el still ends at EOF");
}

is(
    events("<script>x"),
    "start=script|text=x|end=script",
    "trailing content keeps the same events"
);

is(events("<textarea>"), "start=textarea",
    "empty unclosed textarea keeps its old behaviour");

{
    my @events;
    my $p = HTML::Parser->new(
        start_h => [sub { push @events, "start=$_[0]" }, "tagname"],
        end_h   => [sub { push @events, "end=$_[0]" },   "tagname"],
    );
    $p->parse("<script>");
    $p->eof;
    @events = ();
    $p->parse("<p>hi</p>");
    $p->eof;
    is(join("|", @events),
        "start=p|end=p", "object parses normally after the implicit end");
}
