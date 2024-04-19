#!/usr/bin/env raku
use v6.d;

use HTTP::Tiny;
use JSON::Fast;
use WWW::Gemini;

#`[
my $res1 = gemini-generate-content(
        "Write a story with less than 200 words about a magic cigarette.",
        format => 'values', n => 1, max-tokens => 30);

say $res1;
]

#`[
my $res2 = gemini-generate-content(
        "Write a story with less than 200 words about a magic cigarette.",
        generation-method => 'countTokens',
        format => 'values', n => 1);

say $res2;
]


my @queries3 = [
        "Write a story with less than 200 words about a magic cigarette.",
        "What cigarrettes are most popular.",
];

say gemini-embed-content(@queries3,
        task-type => 'RETRIEVAL_DOCUMENT',
        format => 'values');

say gemini-embed-content(@queries3,
        task-type => 'RETRIEVAL_QUERY',
        format => 'values');
