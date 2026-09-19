use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 7;

my $p = HTML::Parser->new(api_version => 3);

$p->handler(start => sub { my $attr = shift; is($attr->{testno}, 1) }, "attr");
$p->handler(end   => sub { shift->eof },                               "self");
my $text;
$p->handler(text => sub { $text = shift }, "text");

is($p->parse("<foo testno=1>"), $p);

$text = '';
ok(!$p->parse("</foo><foo testno=999>"));
ok(!$text);

$p->handler(end => sub { $p->parse("foo"); }, "");

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->parse("</foo>");
        1;
    };
    #>>>
    like($error, qr/^Parse loop not allowed/);
}

# We used to get into an infinite loop if the eof triggered
# handler called ->eof

$p = HTML::Parser->new(api_version => 3);

my $i;
$p->handler(
    "default" => sub {
        my $p = shift;

        #++$i; diag "$i @_";
        $p->eof;
    },
    "self, event"
);
$p->parse("Foo");
$p->eof;

# We used to sometimes trigger events after a handler signaled eof
my $title = '';
$p = HTML::Parser->new(api_version => 3,);
$p->handler(start => \&title_handler, 'tagname, self');
$p->parse("<head><title>foo</title>\n</head>");
is($title, "foo");

# We used to leave the eof flag set when the handler called ->eof during the
# flush, so the next document parsed by the same object was discarded and
# reported the previous document's pending end tag in place of its own events

$p = HTML::Parser->new(api_version => 3);
my @events;
$p->handler(start => sub { push @events, "start=$_[0]" }, "tagname");
$p->handler(end   => sub { push @events, "end=$_[0]" },   "tagname");
$p->handler(
    text => sub {
        my ($self, $chunk) = @_;
        push @events, "text=$chunk";
        $self->eof if $chunk =~ /stop/;
    },
    "self, text"
);

$p->parse("<title>please stop");
$p->eof;

@events = ();
$p->parse("<p>hi</p>");
$p->eof;
is_deeply(\@events, ["start=p", "text=hi", "end=p"]);

sub title_handler {
    return if shift ne 'title';
    my $self = shift;
    $self->handler(text => sub { $title .= shift }, 'dtext');
    $self->handler(
        end => sub { shift->eof if shift eq 'title' },
        'tagname, self'
    );
}
