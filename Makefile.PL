use inc::Module::Install;

name     'XML-Compare';
all_from 'lib/XML/Compare.pm';
author   'Andrew Chilton <andychilton@gmail.com>';
repository 'https://github.com/catalyst/XML-Compare';

requires        "XML::LibXML" => 1.58;  # oldest tested
requires        "Moo" => 2;             # so warnings are not fatal
requires        "MooX::Types::MooseLike";

build_requires 'Test::More';
build_requires 'Test::Builder::Tester';
test_requires 'Test::Exception';

perl_version '5.006'; #As reported by Perl::MinimumVersion

include 'Test::Exception';
include 'Sub::Uplevel';

auto_install;

WriteAll;

