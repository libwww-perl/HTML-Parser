use strict;
use warnings;

# A close tag for a literal element may carry attributes or a slash before
# its ">", and browsers close the element there. The detector used to
# require ">" straight after the name, so such a close tag was swallowed
# as text and everything after it stayed inside the element.

use HTML::Parser ();
use Test::More tests => 12;

sub events {
    my $opts = ref $_[0] ? shift : {};
    my @events;
    my $p = HTML::Parser->new(
        start_h => [sub { push @events, "start=$_[0]" }, "tagname"],
        text_h  => [sub { push @events, "text=$_[0]" },  "text"],
        end_h   => [sub { push @events, "end=$_[0]" },   "tagname"],
    );
    $p->strict_end(1) if $opts->{strict_end};
    $p->parse($_) for @_;
    $p->eof;
    join "|", @events;
}

for my $el (qw( script style title textarea xmp iframe )) {
    is(
        events("<$el>x</$el foo=bar><img src=y>"),
        "start=$el|text=x|end=$el|start=img",
        "attributes on the close tag still close $el"
    );
}

is(
    events("<script>x</script/><img src=y>"),
    "start=script|text=x|end=script|start=img",
    "a slash before the > closes the element"
);

is(
    events("<script>x</SCRIPT FOO=BAR><img src=y>"),
    "start=script|text=x|end=script|start=img",
    "close tag name and attributes may be upper case"
);

is(
    events(qq(<script>x</script foo="a>b">y)),
    "start=script|text=x|end=script|text=y",
    "a > inside a quoted attribute value does not end the tag"
);

is(
    events("<script>x</script foo=", "bar><img src=y>"),
    "start=script|text=x|end=script|start=img",
    "close tag split across chunks"
);

is(
    events("<script>x</scriptx>y</script>z"),
    "start=script|text=x</scriptx>y|end=script|text=z",
    "a longer name does not close the element"
);

is(
    events({strict_end => 1}, "<script>x</script foo=bar>y</script>z"),
    "start=script|text=x</script foo=bar>y|end=script|text=z",
    "strict_end allows only whitespace before the >"
);
