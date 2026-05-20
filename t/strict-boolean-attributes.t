use strict;
use warnings;

use HTML::Parser ();
use Test::More;

# Exercise the strict_boolean_attributes option. Per the HTML spec
# (https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#boolean-attributes)
# only a specific set of attributes are "boolean"; for everything else, an
# attribute that appears without a value should not have its name as its value.
# When strict_boolean_attributes is enabled, non-boolean value-less attributes
# get undef. The default (off) preserves the historic name-as-value behavior.

sub parse_attrs {
    my ($html, %opts) = @_;
    my $p = HTML::Parser->new(api_version => 3);
    $p->strict_boolean_attributes(1) if $opts{strict};
    $p->boolean_attribute_value($opts{bool_attr_val}) if exists $opts{bool_attr_val};

    my %attr;
    $p->handler(
        start => sub { %attr = %{ $_[0] } },
        'attr',
    );
    $p->parse($html)->eof;
    return \%attr;
}

# Accessor returns previous value, defaults to off
{
    my $p = HTML::Parser->new(api_version => 3);
    ok(!$p->strict_boolean_attributes, 'default is off');
    ok(!$p->strict_boolean_attributes(1), 'set to on, accessor returns previous (off)');
    ok($p->strict_boolean_attributes,    'option is now on');
    ok($p->strict_boolean_attributes(0), 'set to off, accessor returns previous (on)');
    ok(!$p->strict_boolean_attributes, 'option is back off');
}

# Default mode preserves historic behavior (no regression)
{
    my $a = parse_attrs('<input checked foo>');
    is($a->{checked}, 'checked', 'default: known boolean keeps name as value');
    is($a->{foo},     'foo',     'default: unknown attr keeps name as value');
}

# Strict mode: known boolean attrs still get their name; unknown get undef
{
    my $a = parse_attrs('<input checked disabled foo bar>', strict => 1);
    is($a->{checked},  'checked',  'strict: checked keeps name');
    is($a->{disabled}, 'disabled', 'strict: disabled keeps name');
    ok(exists $a->{foo}, 'strict: unknown attr key still present');
    is($a->{foo},      undef, 'strict: unknown attr is undef');
    is($a->{bar},      undef, 'strict: another unknown attr is undef');
}

# Regression for C1 (uninitialized-SV bug): same-length, leading-char match,
# later mismatch. Without the fix these produced an uninitialized SV.
{
    my $a = parse_attrs(
        '<x dxsabled cxntrols autopxay aXync foox>',
        strict => 1,
    );
    is($a->{dxsabled}, undef, 'strict: dxsabled (length-collides with disabled) is undef');
    is($a->{cxntrols}, undef, 'strict: cxntrols (length-collides with controls) is undef');
    is($a->{autopxay}, undef, 'strict: autopxay (length-collides with autoplay) is undef');
    is($a->{axync},    undef, 'strict: axync (length-collides with async) is undef');
    is($a->{foox},     undef, 'strict: foox (4 chars, length-collides with loop/open) is undef');
}

# Case-insensitive matching against the spec list
{
    my $a = parse_attrs('<input CHECKED Disabled SeLeCtEd>', strict => 1);
    is($a->{checked},  'CHECKED',  'strict: uppercase CHECKED matches list, value retains source case');
    is($a->{disabled}, 'Disabled', 'strict: mixed-case Disabled matches');
    is($a->{selected}, 'SeLeCtEd', 'strict: jumbled case selected matches');
}

# boolean_attribute_value override applies to matched booleans;
# undef still wins for non-booleans in strict mode.
{
    my $a = parse_attrs(
        '<input checked foo>',
        strict        => 1,
        bool_attr_val => 'YES',
    );
    is($a->{checked}, 'YES', 'strict + bool_attr_val: boolean attr uses configured value');
    is($a->{foo},     undef, 'strict + bool_attr_val: non-boolean still undef');
}

# Without strict mode, boolean_attribute_value applies to everything (historic)
{
    my $a = parse_attrs(
        '<input checked foo>',
        bool_attr_val => 'YES',
    );
    is($a->{checked}, 'YES', 'default + bool_attr_val: boolean attr uses configured value');
    is($a->{foo},     'YES', 'default + bool_attr_val: unknown attr also uses configured value');
}

# Same-length but non-boolean: must not match
{
    my $a = parse_attrs('<x asyna asynb iSmaq>', strict => 1);
    is($a->{asyna}, undef, 'strict: asyna (same length as async, last char differs) is undef');
    is($a->{asynb}, undef, 'strict: asynb (same length as async, last char differs) is undef');
    is($a->{ismaq}, undef, 'strict: iSmaq (same length as ismap, last char differs) is undef');
}

# Every spec-listed boolean attribute should match in strict mode.
{
    my @booleans = qw(
        allowfullscreen
        async
        autofocus
        autoplay
        checked
        compact
        controls
        default
        defer
        disabled
        disablepictureinpicture
        disableremoteplayback
        formnovalidate
        hidden
        inert
        ismap
        itemscope
        loop
        multiple
        muted
        nomodule
        noresize
        noshade
        novalidate
        nowrap
        open
        playsinline
        readonly
        required
        reversed
        selected
        shadowrootclonable
        shadowrootdelegatesfocus
        shadowrootserializable
        truespeed
    );
    for my $b (@booleans) {
        my $a = parse_attrs("<x $b>", strict => 1);
        is($a->{$b}, $b, "strict: $b is recognized as a boolean attribute");
    }
}

# ARG_TOKENS path: also emits undef for non-boolean attrs in strict mode
{
    my $p = HTML::Parser->new(api_version => 3);
    $p->strict_boolean_attributes(1);
    my @tokens;
    $p->handler(
        start => sub { @tokens = @{ $_[0] } },
        'tokens',
    );
    $p->parse('<input checked foo>')->eof;
    is_deeply(
        \@tokens,
        [ 'input', 'checked', 'checked', 'foo', undef ],
        'strict: ARG_TOKENS path emits undef for non-boolean attribute',
    );
}

# ARG_TOKENS in default mode (historic behavior unchanged)
{
    my $p = HTML::Parser->new(api_version => 3);
    my @tokens;
    $p->handler(
        start => sub { @tokens = @{ $_[0] } },
        'tokens',
    );
    $p->parse('<input checked foo>')->eof;
    is_deeply(
        \@tokens,
        [ 'input', 'checked', 'checked', 'foo', 'foo' ],
        'default: ARG_TOKENS path keeps historic name-as-value behavior',
    );
}

done_testing();
