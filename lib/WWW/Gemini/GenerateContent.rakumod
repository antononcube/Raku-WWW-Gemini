use WWW::Gemini::Models;
use WWW::Gemini::Request;
use JSON::Fast;

unit module WWW::Gemini::GenerateContent;


#============================================================
# Message generation
#============================================================

my $messageGenerationStencil = q:to/END/;
{
  "model": "$model",
  "prompt": "$prompt",
  "safetySettings": @safety-settings,
  "maxOutputTokens": $max-output-tokens,
  "temperature": $temperature,
  "candidateCount": $candidate-count,
  "topP" : $top-p,
  "topK" : $top-k
}
END



#| Gemini completion access.
our proto GeminiGenerateContent($prompt is copy,
                                :@images is copy = Empty,
                                :$role = Whatever,
                                :$model = Whatever,
                                :$temperature = Whatever,
                                Numeric :$top-p = 1,
                                :$top-k = Whatever,
                                UInt :n($candidate-count) = 1,
                                :api-key(:$auth-key) = Whatever,
                                UInt :$timeout= 10,
                                :$format= Whatever,
                                Str :$method = 'tiny',
                                Str :$base-url = 'https://generativelanguage.googleapis.com/v1beta/models'
                                ) is export {*}

#| Gemini completion access.
multi sub GeminiGenerateContent(Str $message, *%args) {
    return GeminiGenerateContent([$message,], |%args);
}

#| Gemini completion access.
multi sub GeminiGenerateContent(@messages,
                                :@images is copy = Empty,
                                :$role is copy = Whatever,
                                :$model is copy = Whatever,
                                :$temperature is copy = Whatever,
                                Numeric :$top-p = 1,
                                :$top-k is copy = Whatever,
                                UInt :n($candidate-count) = 1,
                                :api-key(:$auth-key) is copy = Whatever,
                                UInt :$timeout= 10,
                                :$format is copy = Whatever,
                                Str :$method = 'tiny',
                                Str :$base-url = 'https://generativelanguage.googleapis.com/v1beta/models'
                                ) {

    #------------------------------------------------------
    # Process $author
    #------------------------------------------------------

    if $role.isa(Whatever) { $role = 'user'; }
    die "The argument \$author is expected to be a string or Whatever."
    unless $role ~~ Str:D;

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------
    if $model.isa(Whatever) { $model = @images ?? 'gemini-pro-vision' !! 'gemini-pro'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ gemini-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ gemini-known-models;

    #------------------------------------------------------
    # Process $temperature
    #------------------------------------------------------
    if $temperature.isa(Whatever) { $temperature = 0.35; }
    die "The argument \$temperature is expected to be Whatever or number between 0 and 1."
    unless $temperature ~~ Numeric:D && 0 ≤ $temperature ≤ 1;

    #------------------------------------------------------
    # Process $top-p
    #------------------------------------------------------
    if $top-p.isa(Whatever) { $top-p = 1.0; }
    die "The argument \$top-p is expected to be Whatever or number between 0 and 1."
    unless $top-p ~~ Numeric:D && 0 ≤ $top-p ≤ 1;

    #------------------------------------------------------
    # Process $top-k
    #------------------------------------------------------
    die "The argument \$top-k is expected to be Whatever or a positive integer."
    unless $top-k.isa(Whatever) || $top-k ~~ UInt;

    #------------------------------------------------------
    # Process $candidate-count
    #------------------------------------------------------
    die "The argument \$candidate-count is expected to be a positive integer."
    unless 0 < $candidate-count ≤ 8;

    #------------------------------------------------------
    # Messages
    #------------------------------------------------------

    @messages = @messages.map(-> $r {
        given $r {
            when $_ ~~ Pair {
                %(role => $_.key, parts => [ %( text => $_.value), ])
            }
            default {
                %(:$role, parts => [ %(text => $_.Str),])
            }
        }
    }).Array;


    #------------------------------------------------------
    # Messages
    #------------------------------------------------------

    my %generationConfig = :$temperature, topP => $top-p, candidateCount => $candidate-count;

    #------------------------------------------------------
    # Make Gemini URL
    #------------------------------------------------------

    my %body = contents => @messages, :%generationConfig;

    if !$top-k.isa(Whatever) { %body<topK> = $top-k; }

    my $url = "$base-url/{ $model }:generateContent";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return gemini-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
