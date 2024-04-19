unit module WWW::Gemini::Request;

use JSON::Fast;
use HTTP::Tiny;

#============================================================
# Safety settings
#============================================================

#`[
  "safety_settings": [
    {
      "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
      "threshold": "BLOCK_NONE"
    },
    {
      "category": "HARM_CATEGORY_HATE_SPEECH",
      "threshold": "BLOCK_LOW_AND_ABOVE"
    },
    {
      "category": "HARM_CATEGORY_HARASSMENT",
      "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
    {
      "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
      "threshold": "BLOCK_ONLY_HIGH"
    }
  ]
]

our constant @safety-categories = <HARM_CATEGORY_SEXUALLY_EXPLICIT HARM_CATEGORY_HATE_SPEECH HARM_CATEGORY_HARASSMENT HARM_CATEGORY_DANGEROUS_CONTENT>;
our constant @safety-thresholds = <BLOCK_NONE BLOCK_LOW_AND_ABOVE BLOCK_MEDIUM_AND_ABOVE BLOCK_ONLY_HIGH>;

sub safety-spec-whatever() is export {
    my @res = @safety-categories.map({ %( category => $_, threshold => 'BLOCK_NONE' ) }).Array;
    return @res;
}

proto sub safety-spec-set(@sspec, $val) is export {*}

multi sub safety-spec-set(@sspec, Str $th is copy) {
    if !$th.starts-with('BLOCK_') {
        $th = 'BLOCK_' ~ $th.uc;
    }
    die "The second argument is exepcted to be a string, one of: <{@safety-thresholds.join(', ')}>."
    unless $th ∈ @safety-thresholds;

    my @sspec2;
    for @sspec -> $e {
        die 'The first argument is expected to be a list of maps, each map with keys "category" and "threshold".'
        unless ($e ~~ Map) && ($e<category>:exists);

        @sspec2.push( %( category => $e<category>, threshold => $th) );
    }

    return @sspec2;
}

sub safety-spec-all-at($spec) is export {
    return safety-spec-set(safety-spec-whatever, $spec);
}

sub safety-spec-convert(%spec) is export {
    my @res = %spec.map({ %( category => $_.key, threshold => $_.value ) });
    return @res;
}

#============================================================
# Embedding task types
#============================================================

our constant @embedding-task-types = <RETRIEVAL_QUERY RETRIEVAL_DOCUMENT SEMANTIC_SIMILARITY CLASSIFICATION CLUSTERING>;


#============================================================
# POST Tiny call
#============================================================

proto sub tiny-post(Str :$url!, |) is export {*}

multi sub tiny-post(Str :$url!,
                    Str :$body!,
                    Str :api-key(:$auth-key)!,
                    UInt :$timeout = 10) {

    my $resp = HTTP::Tiny.post: $url ~ "?key={ %*ENV<GEMINI_API_KEY> // %*ENV<PALM_API_KEY> // $auth-key }",
            headers => { Content-Type => "application/json" },
            content => $body;

    return $resp<content>.decode;
}

multi sub tiny-post(Str :$url!,
                    :$body! where *~~ Map,
                    Str :api-key(:$auth-key)!,
                    Bool :$json = False,
                    UInt :$timeout = 10) {
    if $json {
        return tiny-post(:$url, body => to-json($body), :$auth-key, :$timeout);
    }
    my $resp = HTTP::Tiny.post: $url ~ "?key={ %*ENV<GEMINI_API_KEY> // %*ENV<PALM_API_KEY> // $auth-key }", content => $body;
    return $resp<content>.decode;
}


#============================================================
# POST Curl call
#============================================================
my $curlQuery = q:to/END/;
curl $URL?key=$PALM_API_KEY \
    -H 'Content-Type: application/json' \
    -X POST \
    -d '$BODY'
END

multi sub curl-post(Str :$url!, Str :$body!, Str :api-key(:$auth-key)!, UInt :$timeout = 10) {

    my $textQuery = $curlQuery
            .subst('$URL', $url)
            .subst('$PALM_API_KEY', $auth-key)
            .subst('$BODY', $body);
    my $proc = shell $textQuery, :out, :err;

    say $proc.err.slurp(:close);

    return $proc.out.slurp(:close);
}

my $curlFormQuery = q:to/END/;
curl $URL?key=$PALM_API_KEY \
  --header 'Authorization: Bearer $PALM_API_KEY' \
  --header 'Content-Type: multipart/form-data'
END

multi sub curl-post(Str :$url!,
                    :$body! where *~~ Map,
                    Str :api-key(:$auth-key)!,
                    UInt :$timeout = 10) {

    my $textQuery = $curlFormQuery
            .subst('$URL', $url)
            .subst('$PALM_API_KEY', $auth-key)
            .trim-trailing;

    for $body.kv -> $k, $v {
        my $sep = $k eq 'file' ?? '@' !! '';
        $textQuery ~= " \\\n  --form $k=$sep$v";
    }

    my $proc = shell $textQuery, :out, :err;

    say $proc.err.slurp(:close);

    return $proc.out.slurp(:close);
}


#============================================================
# Request
#============================================================

#| Gemini request access.
our proto gemini-request(Str :$url!,
                         :$body!,
                         :api-key(:$auth-key) is copy = Whatever,
                         UInt :$timeout= 10,
                         :$format is copy = Whatever,
                         Str :$method = 'tiny',
                         ) is export {*}

#| Gemini request access.
multi sub gemini-request(Str :$url!,
                         :$body!,
                         :api-key(:$auth-key) is copy = Whatever,
                         UInt :$timeout= 10,
                         :$format is copy = Whatever,
                         Str :$method = 'tiny'
                         ) {

    #------------------------------------------------------
    # Process $format
    #------------------------------------------------------
    if $format.isa(Whatever) { $format = 'Whatever' }
    die "The argument format is expected to be a string or Whatever."
    unless $format ~~ Str;

    #------------------------------------------------------
    # Process $method
    #------------------------------------------------------
    die "The argument \$method is expected to be a one of 'curl' or 'tiny'."
    unless $method ∈ <curl tiny>;

    #------------------------------------------------------
    # Process $auth-key
    #------------------------------------------------------
    if $auth-key.isa(Whatever) {
        if %*ENV<GEMINI_API_KEY>:exists {
            $auth-key = %*ENV<GEMINI_API_KEY>;
        } elsif %*ENV<PALM_API_KEY>:exists {
            $auth-key = %*ENV<PALM_API_KEY>;
        } else {
            # Adhering to Gemini's error result template.
            fail %( error => %(
                message => 'Cannot find Gemini authorization key. ' ~
                        'Please provide a valid key to the argument auth-key, or set at least one of the ENV variables GEMINI_API_KEY or PALM_API_KEY.',
                code => 401, status => 'NO_API_KEY'));
        }
    }
    die "The argument auth-key is expected to be a string or Whatever."
    unless $auth-key ~~ Str;

    #------------------------------------------------------
    # Invoke Gemini service
    #------------------------------------------------------
    my $res = do given $method.lc {
        when 'curl' {
            curl-post(:$url, :$body, :$auth-key, :$timeout);
        }
        when 'tiny' {
            tiny-post(:$url, :$body, :$auth-key, :$timeout);
        }
        default {
            die 'Unknown method.'
        }
    }

    #------------------------------------------------------
    # Result
    #------------------------------------------------------
    without $res { return Nil; }

    if $format.lc ∈ <asis as-is as_is> { return $res; }

    if $method ∈ <curl tiny> && $res ~~ Str {
        try {
            $res = from-json($res);
        }
        if $! {
            note 'Cannot convert from JSON, returning "asis".';
            return $res;
        }
    }

    if $res ~~ Map && $res<error> {
        fail $res;
    }

    return do given $format.lc {
        when $_ eq 'values' {
            if $res<candidates>:exists {
                # Assuming text completion
                my @res2 = $res<candidates>.map({
                    if $_<content> {
                        my @t = $_<content><parts>.map({ $_<text> });
                        @t.elems == 1 ?? @t[0] !! @t
                    } else {
                        "No content, finish reason: {$_<finishReason>}";
                    }
                }).Array;
                @res2.elems == 1 ?? @res2[0] !! @res2;
            } elsif $res<embedding> {
                # Assuming text embedding
                $res<embedding><values>;
            } elsif $res<totalTokens> {
                # Assuming token counting
                $res<totalTokens>;
            } else {
                $res
            }
        }
        when $_ ∈ <whatever hash raku> { $res; }
        when $_ ∈ <json> { to-json($res); }
        default { $res; }
    }
}
