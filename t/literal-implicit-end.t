use strict;
use warnings;

# Every literal element left open at EOF gets an implicit end event, with
# or without content after its start tag. plaintext is the exception, as
# it has no end tag at all.

use HTML::Parser ();
use Test::More tests => 16;

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

my @literal = qw( script style title xmp iframe textarea );

for my $el (@literal) {
    is(events("<$el>"), "start=$el|end=$el", "empty unclosed $el ends at EOF");
}

for my $el (@literal) {
    is(events("<$el>x"), "start=$el|text=x|end=$el",
        "unclosed $el with content ends after its text");
}

is(events("<plaintext>x"), "start=plaintext|text=x",
    "plaintext has no end tag, so it gets no implicit end");

is(
    events("<xmp>x<img src=y>"),
    "start=xmp|text=x<img src=y>|end=xmp",
    "markup after an unclosed xmp is still its text"
);

is(
    events("<textarea>x</textarea>y"),
    "start=textarea|text=x|end=textarea|text=y",
    "a closed textarea is unaffected"
);

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
