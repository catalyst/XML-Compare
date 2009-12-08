#!/usr/bin/perl

use strict;
use warnings;
use Test::XML::Compare tests => 4;

# $Test::XML::Compare::VERBOSE = 1;

my $tests = [
   {
       name => 'Basic',
       xml1 => '<foo></foo>',
       xml2 => '<foo></foo>',
   },
   {
       name => 'Basic with TextNode',
       xml1 => '<foo>Hello, World!</foo>',
       xml2 => '<foo>Hello, World!</foo>',
   },
   {
       name => 'Basic with NS',
       xml1 => '<foo xmlns="urn:foo"></foo>',
       xml2 => '<f:foo xmlns:f="urn:foo"></f:foo>',
   },
   {
       name => 'Some Attributes',
       xml1 => '<foo foo="bar" baz="buz"></foo>',
       xml2 => '<foo baz="buz" foo="bar"></foo>',
   },
];

foreach my $t ( @$tests ) {
    is_xml_same($t->{xml1}, $t->{xml2}, $t->{name});
}
