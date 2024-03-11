use v6.d;

use lib '.';
use lib './lib';

use WWW::Gemini;
use Image::Markup::Utilities;
use Test;

my $method = 'tiny';

plan *;

## 1
my $img1FileName = $*CWD ~ '/resources/ThreeHunters.jpg';
my $img1 = image-import($img1FileName);

isa-ok
        gemini-generation( "What do you see in the image?", images => [$img1,], format => 'values'),
        Str,
        'Image vision using image';

## 2
isa-ok
        gemini-generation( "What do you see in the image?", images => [$img1FileName,], format => 'values'),
        Str,
        'Image vision using image file path';

done-testing;
