use strict;
use warnings;
use utf8;

use HTML::Parser ();
use Test::More tests => 16;

my $p = HTML::Parser->new(api_version => 3, ignore_tags => [qw(b i em tt)],);
$p->ignore_elements("script");
$p->unbroken_text(1);

$p->handler(default => [], "event, text");
$p->parse(<<"EOT")->eof;
<html><head><title>foo</title><Script language="Perl">
   while (<B>) {
      # ...
   }
</Script><body>
This is an <i>italic</i> and <b>bold</b> text.
</body>
</html>
EOT

my $t = join("||", map join("|", @$_), @{$p->handler("default")});

#diag $t;

is(
    $t,
    "start_document|||start|<html>||start|<head>||start|<title>||text|foo||end|</title>||start|<body>||text|
This is an italic and bold text.
||end|</body>||text|
||end|</html>||text|
||end_document|", 'ignore_elements'
);


#------------------------------------------------------

$p = HTML::Parser->new(api_version => 3);
$p->report_tags("a");
$p->handler(
    start => sub {
        my ($tagname, %attr) = @_;
        ok($tagname eq "a" && $attr{href} eq "#a", 'report_tags start');
    },
    'tagname, @attr'
);
$p->handler(
    end => sub {
        my $tagname = shift;
        is($tagname, "a", 'report_tags end');
    },
    'tagname'
);

$p->parse(<<EOT)->eof;

<h1>Next example</h1>

This is <a href="#a">very nice</a> example.

EOT


#------------------------------------------------------

my @tags;
$p = HTML::Parser->new(api_version => 3);
$p->report_tags(qw(a em));
$p->ignore_tags(qw(em));
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>

This is <em>yet another</em> <a href="#a">very nice</a> example.

EOT
is(join('|', @tags), 'a', 'report_tags followed by ignore_tags');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->report_tags(qw(h1));
$p->report_tags();
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>

EOT
is(join('|', @tags), 'h1|h2', 'reset report_tags filter');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->report_tags(qw(h1 h2));
$p->ignore_tags(qw(h2));
$p->report_tags(qw(h1 h2));
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>

EOT
is(join('|', @tags), 'h1', 'report_tags does not reset ignore_tags');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->report_tags(qw(h1 h2));
$p->ignore_tags(qw(h2));
$p->report_tags();
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>

EOT
is(join('|', @tags), 'h1', 'reset report_tags does no reset ignore_tags');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->report_tags(qw(h1 h2));
$p->report_tags(qw(h3));
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>
<h3>Next example</h3>

EOT
is(join('|', @tags), 'h3', 'report_tags replaces filter');


#------------------------------------------------------


@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->ignore_tags(qw(h1 h2));
$p->ignore_tags(qw(h3));
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>
<h3>Next example</h3>

EOT
is(join('|', @tags), 'h1|h2', 'ignore_tags replaces filter');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->ignore_tags(qw(h2));
$p->ignore_tags();
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>

EOT
is(join('|', @tags), 'h1|h2', 'reset ignore_tags filter');


#------------------------------------------------------

@tags = ();
$p    = HTML::Parser->new(api_version => 3);
$p->ignore_tags(qw(h2));
$p->report_tags(qw(h1 h2));
$p->handler(end => sub { push @tags, @_; }, 'tagname');

$p->parse(<<EOT)->eof;

<h1>Next example</h1>
<h2>Next example</h2>

EOT
is(join('|', @tags), 'h1', 'ignore_tags before report_tags');

#------------------------------------------------------

$p = HTML::Parser->new(api_version => 3);
$p->ignore_elements("script");
my $res = "";
$p->handler(default => sub { $res .= $_[0]; }, 'text');
$p->parse(<<'EOT')->eof;
A <script> B </script> C </script> D <script> E </script> F
EOT
is($res, "A  C  D  F\n", "ignore </script> without <script> correctly");

#------------------------------------------------------

for my $el (qw( title script style )) {
    $p = HTML::Parser->new(api_version => 3);
    $p->ignore_elements("p");
    my @events;
    $p->handler(default => sub { push @events, $_[0] }, "event");
    $p->parse("<p><$el>x")->eof;
    is(join("|", grep !/_document/, @events),
        "", "no implicit end leaks from an unclosed $el in an ignored element");
}

{
    $p = HTML::Parser->new(api_version => 3);
    my @events;
    $p->handler(start => sub { push @events, "start=$_[0]" }, "tagname");
    $p->handler(text  => sub { push @events, "text=$_[0]" },  "text");
    $p->handler(end   => sub { push @events, "end=$_[0]" },   "tagname");
    $p->parse("<title>x")->eof;
    is(
        join("|", @events),
        "start=title|text=x|end=title",
        "unfiltered title keeps text before its implicit end"
    );
}
