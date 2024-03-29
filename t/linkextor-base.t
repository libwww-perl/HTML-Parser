use strict;
use warnings;

use HTML::LinkExtor ();
use URI             ();
use Test::More tests => 4;

# This test that HTML::LinkExtor really absolutize links correctly
# when a base URL is given to the constructor.

# Try with base URL and the $p->links interface.
my $p = HTML::LinkExtor->new(undef, "http://www.sn.no/foo/foo.html");
$p->parse(<<HTML)->eof;
<head>
<base href="http://www.sn.no/">
</head>
<body>
<form action="/post_here">
</form>

This is <A HREF="link.html">link</a> and an <img SRC="img.jpg"
alt="Image">.
HTML

my @links = $p->links;

# There should be 4 links in the document
is(@links, 4);

my $t;
my %attr;
for (@links) {
    ($t, %attr) = @$_ if $_->[0] eq 'img';
}

is($t, 'img');

is(delete $attr{src}, "http://www.sn.no/foo/img.jpg");

# there should be no more attributes
ok(!scalar(keys %attr));
