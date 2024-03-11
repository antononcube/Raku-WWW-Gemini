use v6.d;

use lib '.';
use lib './lib';

use WWW::Gemini;
use Test;

my $method = 'tiny';

plan *;

## 1
ok gemini-prompt(path => 'models', :$method);

## 2
ok gemini-prompt('What is the most important word in English today?', :$method);

## 3
isa-ok
        gemini-prompt('What is the most important word in English today?', :$method, format => 'values'),
        Str,
        'string result';

## 4
ok gemini-prompt('Generate Raku code for a loop over a list', generation-method => 'generateContent', model => Whatever, :$method);

## 5
ok gemini-prompt('Generate Raku code for a loop over a list', path => 'countTokens', model => 'gemini-pro', :$method);

done-testing;
