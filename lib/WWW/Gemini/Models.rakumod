unit module WWW::Gemini::Models;

use HTTP::Tiny;
use JSON::Fast;



#============================================================
# Known models
#============================================================
# https://ai.google.dev/models/gemini

my $knownModels = Set.new(<gemini-pro gemini-1.0-pro-001 gemini-1.0-pro gemini-1.0-pro-latest gemini-1.5-pro-latest gemini-pro-vision embedding-001 aqa>);


our sub gemini-known-models() is export {
    return $knownModels;
}

#============================================================
# Compatibility of models and end-points
#============================================================

# Taken from:
# https://ai.google.dev/models/gemini

my %endPointToModels =
        'embedContent' => <embedding-001>,
        'generateContent' => <gemini-pro gemini-1.0-pro-001 gemini-1.0-pro gemini-1.0-pro-latest gemini-1.5-pro-latest gemini-pro-vision>,
        'generateAnswer' => <aqa>;

#| End-point to models retrieval.
proto sub gemini-end-point-to-models(|) is export {*}

multi sub gemini-end-point-to-models() {
    return %endPointToModels;
}

multi sub gemini-end-point-to-models(Str $endPoint) {
    return %endPointToModels{$endPoint};
}


#------------------------------------------------------------
# Invert to get model-to-end-point correspondence.
# At this point (2023-04-14) only the model "whisper-1" has more than one end-point.
my %modelToEndPoints = %endPointToModels.map({ $_.value.Array X=> $_.key }).flat.classify({ $_.key }).map({ $_.key => $_.value>>.value.Array });

#| Model to end-points retrieval.
proto sub gemini-model-to-end-points(|) is export {*}

multi sub gemini-model-to-end-points() {
    return %modelToEndPoints;
}

multi sub gemini-model-to-end-points(Str $model) {
    return %modelToEndPoints{$model};
}

#============================================================
# Models
#============================================================

#| Gemini models.
our sub GeminiModels(:api-key(:$auth-key) is copy = Whatever, UInt :$timeout = 10) is export {
    #------------------------------------------------------
    # Process $auth-key
    #------------------------------------------------------
    # This code is repeated in other files.
    if $auth-key.isa(Whatever) {
        if %*ENV<GEMINI_API_KEY>:exists {
            $auth-key = %*ENV<GEMINI_API_KEY>;
        } elsif %*ENV<PALM_API_KEY>:exists {
                $auth-key = %*ENV<PALM_API_KEY>;
        } else {
            note 'Cannot find Gemini authorization key. ' ~
                    'Please provide a valid key to the argument auth-key, or set at least one the ENV variables GEMINI_API_KEY or PALM_API_KEY.';
            $auth-key = ''
        }
    }
    die "The argument auth-key is expected to be a string or Whatever."
    unless $auth-key ~~ Str;

    #------------------------------------------------------
    # Retrieve
    #------------------------------------------------------
    my Str $url = 'https://generativelanguage.googleapis.com/v1beta/models';

    my $resp = HTTP::Tiny.get: $url ~ "?key=$auth-key";

    my $res = from-json($resp<content>.decode);

    return $res<models>.map({ $_<name> });
}
