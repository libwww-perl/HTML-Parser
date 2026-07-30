use strict;
use warnings;

# An unclosed literal element inside a marked section must report its
# events in the same order as one outside, start, then text, then the
# implicit end. The EOF flush used to emit the end for script and style
# before handing the remaining bytes back to the parser, so their end
# arrived before their text, while title deferred its end and got the
# order right.

use HTML::Parser ();
use Test::More tests => 16;

my $error;
{
    local $@;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        HTML::Parser->new->marked_sections(1);
        1;
    };
    #>>>
}

sub events {
    my @events;
    my $p = HTML::Parser->new(
        start_h         => [sub { push @events, "start=$_[0]" }, "tagname"],
        text_h          => [sub { push @events, "text=$_[0]" },  "text"],
        end_h           => [sub { push @events, "end=$_[0]" },   "tagname"],
        marked_sections => 1,
    );
    $p->parse(shift);
    $p->eof;
    join "|", @events;
}

SKIP: {
    skip $error, 16 if $error;

    {
        my @events;
        my $p = HTML::Parser->new(
            start_h         => [sub { push @events, "start=$_[0]" }, "tagname"],
            text_h          => [sub { push @events, "text=$_[0]" }, "text"],
            end_h           => [sub { push @events, "end=$_[0]" }, "tagname"],
            marked_sections => 1,
            case_sensitive  => 1,
        );
        $p->parse("<![INCLUDE[<SCRIPT>safe]]>");
        $p->eof;
        is(
            join("|", @events),
            "start=SCRIPT|text=safe|end=SCRIPT",
            "the deferred implicit end keeps the start tag's case"
        );
    }

    # A marked section left open must not turn the remaining bytes back
    # into markup. Only its terminator is structure; the rest stays the
    # element's text, just as outside a section.
    for my $el (qw( script title )) {
        my $tail = "x</$el\0><img src=y onerror=boom>";
        is(
            events("<![INCLUDE[<$el>$tail"),
            "start=$el|text=$tail|end=$el",
            "open section: NUL-broken $el close stays text"
        );

        is(
            events("<![INCLUDE[<$el>safe<img src=x onerror=boom>"),
            "start=$el|text=safe<img src=x onerror=boom>|end=$el",
            "open section: unclosed $el exposes no markup"
        );

        is(
            events("<![INCLUDE[<$el>x]]><p>hi"),
            "start=$el|text=x|end=$el|start=p|text=hi",
            "closed section: markup after the terminator is parsed"
        );
    }

    for my $el (qw( script style title )) {
        is(events("<![INCLUDE[<$el>safe"),
            "start=$el|text=safe|end=$el",
            "open section: $el ends after its text");

        is(events("<![INCLUDE[<$el>safe]]>"),
            "start=$el|text=safe|end=$el",
            "closed section: $el ends after its text");

        is(
            events("<![INCLUDE[<$el>safe]]><img src=x>"),
            "start=$el|text=safe|end=$el|start=img",
            "closed section: $el ends before markup after the terminator"
        );
    }
}
