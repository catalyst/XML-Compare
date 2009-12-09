use inc::Module::Install;

name     'XML-Compare';
all_from 'lib/XML/Compare.pm';
author   'Andrew Chilton <andychilton@gmail.com>';

requires        "XML::LibXML" => 1.58;  # oldest tested

build_requires 'Test::More';
build_requires 'Test::Builder::Tester';
test_requires 'Test::Exception';

include 'Test::Exception';
include 'Sub::Uplevel';

auto_install;

WriteAll;

