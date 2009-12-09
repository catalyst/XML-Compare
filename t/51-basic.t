#!/usr/bin/perl

use strict;
use warnings;
use Test::Builder::Tester;

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
   {
       name => 'Some Attributes',
       xml1 => '<foo foo="bar" baz="buz"></foo>',
       xml2 => '<foo baz="bar" foo="buz"></foo>',
       fail => 1,
   },
];

test_out("1..".scalar @$tests);
require Test::XML::Compare;
Test::XML::Compare->import(tests => scalar @$tests);
test_test("planned test OK");

my $test_num = 1;
my $test_name;
my $map_out = sub {
	my $expected = shift;
	my @ex = ref $expected ? @$expected : $expected;
	s{##}{$test_num}g for @ex;
	s{XXX}{$test_name}g for @ex;
	@ex;
};

foreach my $t ( @$tests ) {
    $test_name = $t->{name};
    my $output = $t->{output};
    if ( !$output ) {
	    $output = ($t->{fail}?"not ":"")
		    ."ok ## - XXX";
    }
    test_out($map_out->($output));
    if ( my $fail = $t->{fail} ) {
	    test_fail(6);
    }
    if ( my $err = $t->{err} ) {
	    test_err($map_out->($err));
    }
    is_xml_same($t->{xml1}, $t->{xml2}, $t->{name});
    test_test("$test_name - test output OK");
}
