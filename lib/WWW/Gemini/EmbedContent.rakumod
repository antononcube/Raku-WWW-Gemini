unit module WWW::Gemini::EmbedContent;

use WWW::Gemini::Models;
use WWW::Gemini::Request;
use JSON::Fast;



#============================================================
# Message generation
#============================================================

my $textEmbeddingStencil = q:to/END/;
{
  "model": "$model",
  "text": "$prompt"
}
END



#| Gemini completion access.
our proto GeminiEmbedContent($prompt is copy,
                             :$model is copy = Whatever,
                             Str :$generation-method = 'embedContent',
                             :api-key(:$auth-key) is copy = Whatever,
                             UInt :$timeout= 10,
                             :$format is copy = Whatever,
                             Str :$method = 'tiny',
                             Str :$base-url = 'https://generativelanguage.googleapis.com/v1beta/models'
                             ) is export {*}

#| Gemini completion access.
multi sub GeminiEmbedContent(@prompts, *%args) {
    return @prompts.map({ GeminiEmbedContent($_, |%args) });
}

#| Gemini completion access.
multi sub GeminiEmbedContent($prompt is copy,
                             :$model is copy = Whatever,
                             Str :$generation-method = 'embedContent',
                             :api-key(:$auth-key) is copy = Whatever,
                             UInt :$timeout= 10,
                             :$format is copy = Whatever,
                             Str :$method = 'tiny',
                             Str :$base-url = 'https://generativelanguage.googleapis.com/v1beta/models') {

    #------------------------------------------------------
    # Process $prompt
    #------------------------------------------------------
    $prompt = do given $prompt {
        when Str {
            %(parts => [%( text => $_), ]);
        }
        when ($_ ~~ Iterable) && $_.all ~~ Str {
            %(parts => $_.map({ %(text => $prompt) }) );
        }
    }

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------

    if $model.isa(Whatever) { $model = 'embedding-001'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ gemini-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ gemini-known-models;

    #------------------------------------------------------
    # Make Gemini URL
    #------------------------------------------------------

    my %body = content => $prompt;

    my $url = "$base-url/$model:$generation-method";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return gemini-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
