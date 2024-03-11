#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use HTTP::Tiny;
use JSON::Fast;
use WWW::Gemini;


my $res1 = gemini-generate-content(
        "Write a story with less than 200 words about a magic cigarette.",
        format => 'values', n => 1, max-tokens => 30);

say $res1;

#`[
my $res2 = gemini-generate-content(
        "Write a story with less than 200 words about a magic cigarette.",
        generation-method => 'countTokens',
        format => 'values', n => 1);

say $res2;
]

#`[

my $res3 = gemini-embed-content(
        [
            "Write a story with less than 200 words about a magic cigarette.",
            "What cigarrettes are most popular.",
        ],
        format => 'values');

say $res3;
]