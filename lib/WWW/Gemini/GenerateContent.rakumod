unit module WWW::Gemini::GenerateContent;

use WWW::Gemini::Models;
use WWW::Gemini::Request;
use JSON::Fast;
use Image::Markup::Utilities;

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
                                :max-tokens(:$max-output-tokens) is copy = Whatever,
                                :$temperature = Whatever,
                                Numeric :$top-p = 1,
                                :$top-k = Whatever,
                                UInt :n(:$candidate-count) = 1,
                                Str :$generation-method = 'generateContent',
                                :$safety-settings = Whatever,
                                :@tools = Empty,
                                :toolConfig(:%tool-config) = %(),
                                :api-key(:$auth-key) = Whatever,
                                UInt :$timeout= 10,
                                :$format= Whatever,
                                Str :$method = 'tiny',
                                Str :$base-url = 'https://generativelanguage.googleapis.com/v1beta/models',
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
                                :max-tokens(:$max-output-tokens) is copy = Whatever,
                                :$temperature is copy = Whatever,
                                Numeric :$top-p = 1,
                                :$top-k is copy = Whatever,
                                UInt :n(:$candidate-count) = 1,
                                Str :$generation-method is copy = 'generateContent',
                                :$safety-settings is copy = Whatever,
                                :@tools = Empty,
                                :toolConfig(:%tool-config) = %(),
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
    # As state in Gemini's API documentation:
    # Note: gemini-pro is an alias for gemini-1.0-pro.
    # https://ai.google.dev/gemini-api/docs/models/gemini#gemini-1.0-pro
    #if $model.isa(Whatever) { $model = @images ?? 'gemini-pro-vision' !! 'gemini-2.0-flash'; }
    if $model.isa(Whatever) { $model = $generation-method eq 'generateImage' ?? 'gemini-2.0-flash' !! 'gemini-2.0-flash-lite'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ gemini-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ gemini-known-models;

    #------------------------------------------------------
    # Process $max-output-tokens
    #------------------------------------------------------
    if $max-output-tokens.isa(Whatever) { $max-output-tokens = 1024; }
    die "The argument \$max-output-tokens is expected to be Whatever or a positive integer."
    unless $max-output-tokens ~~ Int && 0 < $max-output-tokens;

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
    # Process $safety-settings
    #------------------------------------------------------
    $safety-settings = do given $safety-settings {
        when Str:D { safety-spec-all-at($safety-settings) }
        when Whatever { safety-spec-whatever; }
        when Map { [$safety-settings,] }
        default { $safety-settings }
    }

    die "The argument \$safety-settings is expected to be a string, a map, a list of maps, or Whatever."
    unless $safety-settings ~~ Positional && $safety-settings.all ~~ Map;

    #------------------------------------------------------
    # Process @images
    #------------------------------------------------------

    my &b64-mmd = / ^ \h* '![](data:image/' \w*? ';base64' /;
    @images = @images.map({ $_ ~~ Str && $_ ~~ &b64-mmd ?? $_.subst(/^ \h* '![](' /).chop !! $_ });

    die "The argument \@images is expected to be an empty Positional or a list of JPG image file names, image URLs, or base64 images."
    unless !@images ||
            [&&] @images.map({
                $_ ~~ / ^ 'http' .? '://' / || $_.IO.e || $_ ~~ / ^ 'data:image/' \w*? ';base64' /
            });

    #------------------------------------------------------
    # Messages
    #------------------------------------------------------

    @messages = @messages.map(-> $r {
        given $r {
            when $_ ~~ Pair:D {
                %(role => $_.key, parts => [%( text => $_.value),])
            }
            when $_ ~~ Map:D && ($_<role>:exists) {
                # Not making checks like  ($_<role>:exists) && ($_<parts>:exists)
                # because tool workflows might attach messages with keys like <type call_id output>.
                $_
            }
            when $_ ~~ Map:D {
                note "Potentially problematic message: no role specified.";
                $_
            }
            default {
                %(:$role, parts => [%(text => $_.Str),])
            }
        }
    }).Array;

    if @images {
        my $content = [
            %( text => @messages.tail.<parts>.tail<text> ),
            %( inline_data => @images.map({
                %(
                    mime_type => 'image/jpeg',
                    data => ($_.IO.e ?? image-encode($_, type => 'jpeg') !! $_).subst(/ ^ \h* ['![](']? 'data:image/' \w* ';base64,'/)
                ) }).tail
            )
        ];
        @messages = @messages.head(*- 1).Array.push({ parts => $content });
    }

    #------------------------------------------------------
    # Configuration
    #------------------------------------------------------

    my %generationConfig = :$temperature,
                           topP => $top-p,
                           candidateCount => $candidate-count,
                           maxOutputTokens => $max-output-tokens;

    #------------------------------------------------------
    # Make Gemini URL
    #------------------------------------------------------

    my %body = contents => @messages, :%generationConfig;

    if $safety-settings {
        %body<safety_settings> = $safety-settings;
    }

    if $generation-method eq 'countTokens' {
        %body<generationConfig>:delete;
        %body<safety_settings>:delete;
    }

    if @tools {
        %body<tools> = [ %(functionDeclarations => @tools), ];
    }

    if %tool-config {
        %body<toolConfig> = %tool-config;
    }

    if !$top-k.isa(Whatever) { %body<topK> = $top-k; }

    my $url = "$base-url/$model:$generation-method";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return gemini-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
