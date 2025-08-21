#!/usr/bin/perl
use strict;
use warnings;
use HTML::Parser;

my $p = HTML::Parser->new(
    api_version => 3,
    start_h => [sub {
        my ($tagname, $attr) = @_;
        print "Start tag: $tagname";
        if ($attr && %$attr) {
            print " with attributes: ";
            for my $key (keys %$attr) {
                print "$key='$attr->{$key}' ";
            }
        }
        print "\n";
    }, "tagname,attr"],
    
    end_h => [sub {
        my ($tagname) = @_;
        print "End tag: $tagname\n";
    }, "tagname"],
    
    text_h => [sub {
        my ($text) = @_;
        $text =~ s/^\s+|\s+$//g; # trim whitespace
        print "Text: '$text'\n" if $text;
    }, "dtext"],
);

$p->parse_file("test.html");
$p->eof;