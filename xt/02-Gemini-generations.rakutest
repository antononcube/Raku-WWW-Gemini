use v6.d;

use lib '.';
use lib './lib';

use WWW::Gemini;
use Test;

my $method = 'tiny';

plan *;

## 1
ok gemini-generation('Generate Raku code for a loop over a list', model => Whatever, :$method);

## 2
ok gemini-generation('Generate Raku code for a loop over a list', model => 'gemini-pro', :$method);

## 3
ok gemini-generation('Generate Raku code for a loop over a list', model => 'gemini-1.0-pro', :$method);

done-testing;
