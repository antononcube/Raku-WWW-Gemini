#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use Image::Markup::Utilities;
use WWW::Gemini;

my $url3 = 'https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png';
my $imgBarChart = image-import($url3);
my $img2FileName = $*CWD ~ '/resources/ThreeHunters.jpg';
my $img2 = image-import($img2FileName);

#say gemini-generation( "How many years are in the image? Be as concise as possible in your answers.", images => [$imgBarChart,], format => 'values');
#say gemini-generation( "What do you see in the image?", images => [$img2,], format => 'values');

say gemini-generation( "What do you see in the image?", images => [$img2FileName, ], format => 'values');