use inc::Module::Install;

name     'XML-Compare';
all_from 'lib/XML/Compare.pm';
author   'Andrew Chilton <andychilton@gmail.com>';

requires        "XML::LibXML" => 1.70;

build_requires 'Test::More';

auto_install;

WriteAll;

