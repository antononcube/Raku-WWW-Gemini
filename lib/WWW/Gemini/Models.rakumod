unit module WWW::Gemini::Models;

use HTTP::Tiny;
use JSON::Fast;



#============================================================
# Known models
#============================================================
# https://ai.google.dev/models/gemini

my $knownModels = Set.new(
        <gemini-pro
         gemini-1.0-pro-001 gemini-1.0-pro gemini-1.0-pro-latest
         gemini-1.5-pro-001 gemini-1.5-pro gemini-1.5-pro-latest
         gemini-1.5-flash-001 gemini-1.5-flash gemini-1.5-flash-latest gemini-1.5-flash-8b
         gemini-2.0-pro-exp gemini-2.0-pro-exp-02-05
         gemini-2.0-flash gemini-2.0-flash-lite
         gemini-2.0-flash-001 gemini-2.0-flash-exp gemini-2.0-flash-thinking-exp-01-21
         gemini-2.5-pro-preview-03-25 gemini-2.5-pro-exp-03-25
         gemini-2.5-flash-preview-04-17 gemini-2.5-flash-preview-05-20
         gemini-2.5-pro-preview-05-06
         embedding-001 text-embedding-004 text-embedding-preview-0409 gemini-embedding-exp
         aqa imagen-3.0-generate-002>);


our sub gemini-known-models() is export {
    return $knownModels;
}

#============================================================
# Compatibility of models and end-points
#============================================================

# Taken from:
# https://ai.google.dev/models/gemini

my %endPointToModels =
        'embedContent' => <embedding-001 text-embedding-004 text-embedding-preview-0409 gemini-embedding-exp>,
        'generateContent' =>
                <gemini-pro
                 gemini-1.0-pro-001 gemini-1.0-pro gemini-1.0-pro-latest
                 gemini-1.5-pro-001 gemini-1.5-pro gemini-1.5-pro-latest
                 gemini-1.5-flash-001 gemini-1.5-flash gemini-1.5-flash-latest
                 gemini-2.0-pro-exp gemini-2.0-pro-exp-02-05
                 gemini-2.0-flash gemini-2.0-flash-lite
                 gemini-2.0-flash-001 gemini-2.0-flash-exp gemini-2.0-flash-thinking-exp-01-21
                 gemini-2.5-pro-preview-03-25 gemini-2.5-pro-exp-03-25
                 gemini-2.5-flash-preview-04-17 gemini-2.5-flash-preview-05-20
                 gemini-2.5-pro-preview-05-06
                 gemini-pro-vision gemini-pro-vision-latest>,
        'generateAnswer' => <aqa>,
        'generateImage' => <imagen-3.0-generate-002>;

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
