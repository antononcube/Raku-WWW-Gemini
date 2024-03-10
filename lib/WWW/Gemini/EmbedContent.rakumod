use WWW::Gemini::Models;
use WWW::Gemini::Request;
use JSON::Fast;

unit module WWW::Gemini::EmbedContent;


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
our proto PaLMEmbedText($prompt is copy,
                        :$model is copy = Whatever,
                        :api-key(:$auth-key) is copy = Whatever,
                        UInt :$timeout= 10,
                        :$format is copy = Whatever,
                        Str :$method = 'tiny') is export {*}

#| Gemini completion access.
multi sub PaLMEmbedText(@prompts, *%args) {
    return @prompts.map({ PaLMEmbedText($_, |%args) });
}

#| Gemini completion access.
multi sub PaLMEmbedText($prompt is copy,
                        :$model is copy = Whatever,
                        :api-key(:$auth-key) is copy = Whatever,
                        UInt :$timeout= 10,
                        :$format is copy = Whatever,
                        Str :$method = 'tiny') {

    #------------------------------------------------------
    # Process $prompt
    #------------------------------------------------------
    if $prompt ~~ Str {
        $prompt = %( text => $prompt);
    }

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------

    if $model.isa(Whatever) { $model = 'embedding-gecko-001'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ gemini-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ gemini-known-models;

    #------------------------------------------------------
    # Make Gemini URL
    #------------------------------------------------------

    my %body = $prompt;

    my $url = "https://generativelanguage.googleapis.com/v1beta2/models/{$model}:embedText";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return gemini-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
