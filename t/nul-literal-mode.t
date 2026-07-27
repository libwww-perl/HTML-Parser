use strict;
use warnings;

# An embedded NUL byte inside a literal-mode close tag (script, style, xmp,
# iframe, title, textarea) must not change how following markup is classified.
# A real browser keeps everything after `</tag\0...` as raw text of the literal
# element -- it never creates the injected <img> element. HTML::Parser must
# agree: the <img> must be reported as text, never as a start tag. Otherwise a
# consumer's view of the byte stream diverges from the browser's.

use HTML::Parser ();
use Test::More;

my @elements = qw(script style xmp iframe title textarea);

# Two NUL placements matter and must be tested independently: `\0 ` (NUL then
# space) and `\0>` (NUL immediately before the greater-than). They exercise
# different branches of the close-tag detector.
my @placements = (
    [ 'nul-space', "\0 " ],
    [ 'nul-gt',    "\0>" ],
);

# The NUL byte is only one way to leave a literal element unclosed. The same
# divergence appears with a plainly unclosed element (no close tag at all), so
# cover that too -- the real contract is "an unclosed literal element keeps its
# tail as raw text at EOF, never re-parsed as markup".
my @cases;
for my $elem (@elements) {
    for my $p (@placements) {
        my ($label, $mid) = @$p;
        push @cases,
            [ "$elem/$label", "<$elem>safe</$elem$mid<img src=x onerror=boom>" ];
    }
    push @cases,
        [ "$elem/unclosed", "<$elem>safe<img src=x onerror=boom>" ];
}

plan tests => scalar @cases;

for my $case (@cases) {
    my ($label, $html) = @$case;

    my @start_tags;
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->handler(
        start => sub { push @start_tags, $_[0] },
        'tagname',
    );
    $parser->parse($html);
    $parser->eof;

    my $saw_img = grep { $_ eq 'img' } @start_tags;
    ok(
        !$saw_img,
        "$label: injected <img> stays raw text, not a start tag",
    );
}
