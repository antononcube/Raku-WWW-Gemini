# WWW::Gemini Raku package

Raku package for connecting with [Google's Gemini](https://gemini.google.com/app).
It is based on the Web API described in [Gemini's API documentation](https://ai.google.dev/docs/gemini_api_overview).

The design and implementation of the package closely follows those of 
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp1], and
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2].

## Installation 

From [Zef ecosystem](https://raku.land):

```
zef install WWW::Gemini
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-WWW-Gemini
```

-----

## Usage examples

Show models:

```perl6
use WWW::Gemini;

gemini-models()
```
```
# (models/chat-bison-001 models/text-bison-001 models/embedding-gecko-001 models/gemini-1.0-pro models/gemini-1.0-pro-001 models/gemini-1.0-pro-latest models/gemini-1.0-pro-vision-latest models/gemini-pro models/gemini-pro-vision models/embedding-001 models/aqa)
```

Show text generation:

```perl6
.say for gemini-generate-content('what is the population in Brazil?', format => 'values');
```
```
# 215.3 million (2023)
```

Using a synonym function:

```perl6
.say for gemini-generation('Who wrote the book "Dune"?');
```
```
# {candidates => [{content => {parts => [{text => Frank Herbert}], role => model}, finishReason => STOP, index => 0, safetyRatings => [{category => HARM_CATEGORY_SEXUALLY_EXPLICIT, probability => NEGLIGIBLE} {category => HARM_CATEGORY_HATE_SPEECH, probability => NEGLIGIBLE} {category => HARM_CATEGORY_HARASSMENT, probability => NEGLIGIBLE} {category => HARM_CATEGORY_DANGEROUS_CONTENT, probability => NEGLIGIBLE}]}], promptFeedback => {safetyRatings => [{category => HARM_CATEGORY_SEXUALLY_EXPLICIT, probability => NEGLIGIBLE} {category => HARM_CATEGORY_HATE_SPEECH, probability => NEGLIGIBLE} {category => HARM_CATEGORY_HARASSMENT, probability => NEGLIGIBLE} {category => HARM_CATEGORY_DANGEROUS_CONTENT, probability => NEGLIGIBLE}]}}
```

### Embeddings

Show text embeddings:

```perl6
use Data::TypeSystem;

my @vecs = gemini-embed-content(["say something nice!",
                            "shout something bad!",
                            "wher is the best coffee made?"],
        format => 'values');

say "Shape: ", deduce-type(@vecs);
.say for @vecs;
```
```
# Shape: Vector(Vector((Any), 768), 3)
# [-0.031044435 -0.01293638 0.008904989 -0.03263427 0.012885272 0.012842082 0.027659245 -0.022445966 0.001112788 0.009750604 0.04965804 0.009791873 0.043056853 -0.042573094 -0.00023794426 -0.018873844 0.04166457 0.003571331 0.02574701 -0.023280907 0.0059002587 0.07658169 -0.022190008 -0.0016273775 -0.0012887336 -0.019846706 0.017049292 -0.0529704 -0.03620988 0.039227188 -0.03227184 0.04443834 -0.053984605 -0.042696882 0.024596183 -0.062363494 0.0006710476 0.005082995 0.028102735 0.022241268 0.04491562 -0.029794076 -0.026798483 -0.026482908 0.028277056 -0.015406585 0.00509467 0.021505114 -0.015438571 -0.03986329 0.0509833 -0.026030572 -0.0006995414 -0.010695886 -0.0066410583 -0.007820808 0.0438939 0.049049154 -0.044850092 0.007993297 0.033383675 -0.017981231 -0.018700533 0.018778075 0.0132168755 -0.008311568 -0.014669906 0.012169402 0.04730062 -0.030405547 0.00081983255 -0.06609647 0.03425647 -0.025497716 -0.027294777 -0.13895138 -0.032781336 0.06400365 -0.043568406 0.0003324857 -0.02962398 -0.100292206 -0.052770108 -0.039332274 -0.110844955 0.03195597 -0.025506092 0.020022806 0.009940032 0.050653372 -0.0215141 -0.024635738 -0.005630048 -0.07249384 0.002201602 0.050425064 -0.009672865 -0.043219615 0.011732131 0.0021474056 ...]
# [0.015647776 -0.03143455 -0.040937748 -0.03215229 0.00071876345 0.024444472 -0.013541601 -0.023152746 -0.009198697 0.045432128 0.049105383 -0.0029321243 -0.01180009 -0.044899803 0.025208764 -0.034655575 -0.0047017317 -0.012213489 0.04399379 -0.0031873514 0.017236471 0.0302059 -0.009911401 -0.009729893 0.0067022024 0.007181713 0.047008436 -0.07261744 -0.034597974 0.024742194 -0.049818117 0.047178492 -0.05239612 0.004519767 -0.031770747 -0.084419765 -0.009777399 0.016744321 0.057470873 -0.0008020468 0.0034762728 0.00092191494 -0.012497095 -0.016705612 0.035845324 -0.006399285 0.024325574 -0.002022227 0.002841698 -0.080434985 0.031044094 -0.030748611 0.028753037 -0.036181286 0.00089683925 -0.060913764 0.056072846 0.052506663 -0.03612298 0.030202417 0.017606454 0.0070932843 -0.024513774 0.031895094 0.02637744 -0.048618294 -0.028836755 0.0009879556 0.09044918 0.006353638 0.042316265 -0.053601615 0.0047276323 -0.010463116 -0.03282551 -0.11493026 -0.037989974 0.066172026 -0.042627145 0.0338829 -0.022461282 -0.03243943 -0.0322086 -0.022295073 -0.06273048 -0.020984378 -0.018161116 0.024409954 0.052115202 0.07886858 -0.015862696 -0.0064231334 0.021302955 -0.055992328 -0.01627737 0.074991345 -0.026166856 -0.010036745 0.027091224 -0.024027428 ...]
# [-0.006152287 -0.030394098 -0.014393949 -0.044958446 0.024048664 0.058848683 -0.019440122 -0.03335302 0.0052551543 0.03016256 -0.056723848 0.0165514 0.033588503 -0.0121421805 -0.010177278 0.0044627623 0.010052895 0.03868767 -0.0093852775 -0.04297231 0.012675581 0.00048459045 0.03808999 0.0244966 -0.01783969 -0.04948389 -0.020452937 -0.020111429 -0.071586914 0.021448703 -0.06987287 0.070739485 -0.041175663 -0.025094349 0.036686916 -0.031210283 -0.008054416 0.05591898 0.019917108 0.052107006 -0.01817106 -0.006068624 -0.07173136 0.016163683 0.006998349 -0.030379737 -0.020654308 0.011711265 -0.036781214 -0.055499233 0.00019690607 -0.029976666 0.04581642 -0.00076709985 -0.006552171 -0.0061041717 0.028387297 -0.009770305 -0.028570032 0.026715215 -0.00784403 -0.020735253 -0.03838065 0.05933399 0.018694695 -0.009314481 -0.02369818 0.03813777 0.053727135 -0.036867376 -0.0124868 -0.021107392 0.05045464 -0.034195308 -0.057970576 -0.092570715 -0.046711806 0.07233655 0.06040919 0.025281942 -0.03326588 -0.07678022 0.036464084 0.009779299 -0.024988512 0.00033775502 -0.040992998 0.055793807 0.0017775173 0.05940393 -0.026538428 0.019357659 0.021453092 -0.029973181 -0.009057629 0.02458787 -0.021803178 -0.01956588 -0.0064701564 -0.02464882 ...]
```

### Vision

If the function `gemini-completion` is given a list of images, textual results corresponding to those images is returned.
The argument "images" is a list of image URLs, image file names, or image Base64 representations. (Any combination of those element types.)

Here is an example with three images:

```perl6
my $fname = $*CWD ~ '/resources/ThreeHunters.jpg';
my @images = [$fname,];
say gemini-generation("Give concise descriptions of the images.", :@images, format => 'values');
```
```
# The image shows a family of raccoons in a tree. The mother raccoon is watching over her two cubs. The cubs are playing with each other. There are butterflies flying around the tree. The leaves on the tree are turning brown and orange.
```

When a file name is given to the argument "images" of `gemini-completion` then 
the function `encode-image` of 
["Image::Markup::Utilities"](https://raku.land/zef:antononcube/Image::Markup::Utilities), [AAp4],
is applied to it.


-------

## Command Line Interface

### Maker suite access

The package provides a Command Line Interface (CLI) script:

```shell
gemini-prompt --help
```
```
# Usage:
#   gemini-prompt [<words> ...] [--path=<Str>] [-n[=UInt]] [--mt|--max-output-tokens[=UInt]] [-m|--model=<Str>] [-t|--temperature[=Real]] [-a|--auth-key=<Str>] [--timeout[=UInt]] [-f|--format=<Str>] [--method=<Str>] -- Command given as a sequence of words.
#   
#     --path=<Str>                       Path, one of 'generateContent', 'embedContent', 'countTokens', or 'models'. [default: 'generateContent']
#     -n[=UInt]                          Number of completions or generations. [default: 1]
#     --mt|--max-output-tokens[=UInt]    The maximum number of tokens to generate in the completion. [default: 100]
#     -m|--model=<Str>                   Model. [default: 'Whatever']
#     -t|--temperature[=Real]            Temperature. [default: 0.7]
#     -a|--auth-key=<Str>                Authorization key (to use Gemini API.) [default: 'Whatever']
#     --timeout[=UInt]                   Timeout. [default: 10]
#     -f|--format=<Str>                  Format of the result; one of "json", "hash", "values", or "Whatever". [default: 'values']
#     --method=<Str>                     Method for the HTTP POST query; one of "tiny" or "curl". [default: 'tiny']
```

**Remark:** When the authorization key argument "auth-key" is specified set to "Whatever"
then `gemini-prompt` attempts to use one of the env variables `GEMINI_API_KEY` or `PALM_API_KEY`.


--------

## Mermaid diagram

The following flowchart corresponds to the steps in the package function `gemini-prompt`:

```mermaid
graph TD
	UI[/Some natural language text/]
	TO[/"Gemini<br/>Processed output"/]
	WR[[Web request]]
	Gemini{{Gemini}}
	PJ[Parse JSON]
	Q{Return<br>hash?}
	MSTC[Compose query]
	MURL[[Make URL]]
	TTC[Process]
	QAK{Auth key<br>supplied?}
	EAK[["Try to find<br>GEMINI_API_KEY<br>or<br>PALM_API_KEY<br>in %*ENV"]]
	QEAF{Auth key<br>found?}
	NAK[/Cannot find auth key/]
	UI --> QAK
	QAK --> |yes|MSTC
	QAK --> |no|EAK
	EAK --> QEAF
	MSTC --> TTC
	QEAF --> |no|NAK
	QEAF --> |yes|TTC
	TTC -.-> MURL -.-> WR -.-> TTC
	WR -.-> |URL|Gemini 
	Gemini -.-> |JSON|WR
	TTC --> Q 
	Q --> |yes|PJ
	Q --> |no|TO
	PJ --> TO
```

------

## References


### Articles

[AA1] Anton Antonov,
["Workflows with LLM functions"](https://rakuforprediction.wordpress.com/2023/08/01/workflows-with-llm-functions/),
(2023),
[RakuForPredictions at WordPress](https://rakuforprediction.wordpress.com).

[AA2] Anton Antonov,
["Number guessing games: Gemini vs ChatGPT"](https://rakuforprediction.wordpress.com/2023/08/06/number-guessing-games-gemini-vs-chatgpt/)
(2023),
[RakuForPredictions at WordPress](https://rakuforprediction.wordpress.com).

[ZG1] Zoubin Ghahramani,
["Introducing Gemini 2"](https://blog.google/technology/ai/google-gemini-2-ai-large-language-model/),
(2023),
[Google Official Blog on AI](https://blog.google/technology/ai/).

### Packages, platforms

[AAp1] Anton Antonov,
[WWW::PaLM Raku package](https://github.com/antononcube/Raku-WWW-PaLM),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[WWW::OpenAI Raku package](https://github.com/antononcube/Raku-WWW-OpenAI),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov,
[LLM::Functions Raku package](https://github.com/antononcube/Raku-LLM-Functions),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov,
[Image::Markup::Utilities Raku package](https://github.com/antononcube/Raku-Image-Markup-Utilities),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov,
[ML::FindTextualAnswer Raku package](https://github.com/antononcube/Raku-ML-FindTextualAnswer),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).