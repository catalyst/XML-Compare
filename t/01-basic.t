#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use XML::Compare;

# $XML::Compare::VERBOSE = 1;

my $same = [
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
       name => 'Same Attributes',
       xml1 => '<foo foo="bar" baz="buz"></foo>',
       xml2 => '<foo baz="buz" foo="bar"></foo>',
   },
   {
       name => 'Empty xmlns',
       xml1 => '<foo xmlns=""></foo>',
       xml2 => '<foo ></foo>',
   },
   {
       name => 'Empty xmlns in lower element',
       xml1 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
       xml2 => '<a:foo xmlns:a="uri:a"><nothing xmlns="" /></a:foo>',
   },
];

my $diff = [
   {
       name => 'Different Attributes',
       xml1 => '<foo foo="bar"></foo>',
       xml2 => '<foo baz="buz"></foo>',
   },
   {
       name => 'Empty xmlns in lower element (not same)',
       xml1 => '<foo xmlns="uri:a"><nothing /></foo>',
       xml2 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
   },
   {
       name => 'Empty xmlns in lower element',
       xml1 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
       xml2 => '<a:foo xmlns:a="uri:a"><nothing a:xmlns="" /></a:foo>',
   },
];

foreach my $t ( @$same ) {
    ok( XML::Compare::is_same($t->{xml1}, $t->{xml2}), $t->{name} );
}

foreach my $t ( @$diff ) {
    ok( XML::Compare::is_different($t->{xml1}, $t->{xml2}), $t->{name} );
}
