use inc::Module::Install;

name     'XML-Compare';
all_from 'lib/';
author   'Andrew Chilton <andychilton@gmail.com>';

build_requires 'Test::More';

auto_install;

WriteAll;

