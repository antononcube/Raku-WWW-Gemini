#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use WWW::Gemini;
use WWW::Gemini::Request;


my $res1 = gemini-generate-content(
        "I want to kill them all!!",
        format => 'values', n => 1, max-tokens => 300);

say $res1;

say '=' x 120;

my $res2 = gemini-generate-content(
        "I want to kill them all!!",
        safety-settings => safety-spec-all-at('BLOCK_LOW_AND_ABOVE'),
        format => 'values', n => 1, max-tokens => 300);

say $res2;
