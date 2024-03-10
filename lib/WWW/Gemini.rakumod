use JSON::Fast;
use HTTP::Tiny;

unit module WWW::Gemini;

use WWW::Gemini::EmbedContent;
use WWW::Gemini::GenerateContent;
use WWW::Gemini::Models;

#===========================================================
#| Gemini chat and text completions access.
#| C<:type> -- type of text generation, one of 'chat', 'text', or Whatever;
#| C<:model> -- LLM model to use.
#| C<*%args> -- additional arguments, see C<gemini-generate-content> and C<gemini-generate-text>.
our proto gemini-generation(|) is export {*}

multi sub gemini-generation(*@args, *%args) {
    return gemini-generate-content(|@args, |%args);
}

#===========================================================
#| Gemini chat completions access.
#| C<$prompt> -- message to the LLM;
#| C<:$role> -- role; no more two authors per chat;
#| C<:$model> -- model;
#| C<:$temperature> -- number between 0 and 1;
#| C<:$top-p> -- top probability of tokens to use in the answer;
#| C<$top-k> -- top-K top tokens to use;
#| C<:n($candidate-count)> -- number of answers;
#| C<:api-key($auth-key)> -- authorization key (API key);
#| C<:$timeout> -- timeout;
#| C<:$format> -- format to use in answers post processing, one of <values json hash asis>);
#| C<:$method> -- method to WWW API call with, one of <curl tiny>.
#| C<:$base-url> -- base URL for WWW API server.
our proto gemini-generate-content(|) is export {*}

multi sub gemini-generate-content(**@args, *%args) {
    return WWW::Gemini::GenerateContent::GeminiGenerateContent(|@args, |%args);
}

#===========================================================
#| Gemini embeddings access.
our proto gemini-embed-content(|) is export {*}

multi sub gemini-embed-content(**@args, *%args) {
    return WWW::Gemini::EmbedContent::GeminiEmbedContent(|@args, |%args);
}

#===========================================================
#| Gemini models access.
our proto gemini-models(|) is export {*}

multi sub gemini-models(*%args) {
    return WWW::Gemini::Models::GeminiModels(|%args);
}


#===========================================================
#| Gemini utilization for finding textual answers.
#our proto gemini-find-textual-answer(|) is export {*}
#
#multi sub gemini-find-textual-answer(**@args, *%args) {
#    return WWW::Gemini::FindTextualAnswer::OpenAIFindTextualAnswer(|@args, |%args);
#}


#============================================================
# Playground
#============================================================

#| Gemini maker-suite access.
#| C<:path> -- end point path;
#| C<:api-key(:$auth-key)> -- authorization key (API key);
#| C<:timeout> -- timeout
#| C<:$format> -- format to use in answers post processing, one of <values json hash asis>);
#| C<:$method> -- method to WWW API call with, one of <curl tiny>,
#| C<*%args> -- additional arguments, see C<gemini-generate-content> and C<gemini-generate-text>.
our proto gemini-prompt($text is copy = '',
                      Str :$path = 'generateText',
                      :api-key(:$auth-key) is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny',
                      *%args
                      ) is export {*}

#| Gemini maker-suite access.
multi sub gemini-prompt(*%args) {
    return gemini-prompt('', |%args);
}

#| Gemini maker-suite access.
multi sub gemini-prompt(@texts, *%args) {
    return @texts.map({ gemini-prompt($_, |%args) });
}

#| Gemini maker-suite access.
multi sub gemini-prompt($text is copy,
                      Str :$path = 'generateText',
                      :api-key(:$auth-key) is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny',
                      *%args
                      ) {

    #------------------------------------------------------
    # Dispatch
    #------------------------------------------------------

    given $path {
        when $_ eq 'models' {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/models';
            return gemini-models(:$auth-key, :$timeout);
        }
        when $_ ∈ <message generateMessage message-generation> {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/{model=models/*}:generateMessage';
            my $expectedKeys = <model prompt temperature top-p top-k n candidate-count context examples>;
            return gemini-generate-content($text,
                    |%args.grep({ $_.key ∈ $expectedKeys }).Hash,
                    :$auth-key, :$timeout, :$format, :$method);
        }
        when $_ ∈ <embed embedding embedText text-embedding text-embeddings> {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/{model=models/*}:embedText';
            return gemini-embed-content($text,
                    |%args.grep({ $_.key ∈ <model> }).Hash,
                    :$auth-key, :$timeout, :$format, :$method);
        }
        default {
            die 'Do not know how to process the given path.';
        }
    }
}
