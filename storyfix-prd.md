# StoryFix PRD

## What Is This?

**StoryFix** is a Ruby CLI tool that takes text and performs a fix using an
LLM. For example, changing the pronouns of a protagonist, changing the story
from past tense to present tense, or changing the POV, while preserving the
author's voice, style, and intent as much as possible.

The fixes are prompts to be written by the user and are out of scope. We are
writing an app that receives text, asks an LLM to transform it, and emits the
text. That's it.

## Target User

Someone comfortable with the bash command line who has an OpenRouter API key.

## Technical Constraints

* Use ruby 4
* Use OpenRouter for simplicity. Do not use the anthropic gem. Use OpenRouter's
  published REST api
* Configuration in sqlite db (TODO: Where does storyfix.db live?)
* Use Optimist gem for argument parsing
* Fixes: first argument is the name of the fix
* Fixes are in a sqlite table
* Main script is storyfix. Fixes are storyfix-<command>
* Test with rspec
* Coverage with simplecov
* All code must have 100% spec coverage
* All commits require green specs
* Text input via stdin/stdout or --infile --outfile (both)
* Gem dependencies (optimist, colorize, extralite, etc) are handled with bundler
* Can be published as a rubygem
* CLI install is git clone && bundle install
* Fixes are partial text prompts stored in sqlite

## Argument parsing

Use the optimist gem.

```ruby
opts = Optimist.options do
  banner <<BANNER
storyfix fix - Fix your story with an LLM

Usage:
  storyfix [<options>] <fix> [arguments]

Commands:
  list list fixes
  add <fix> "description" "text"
  remove <fix>
  show <fix>
  get-config <name>
  set-config <name> <value>
  list-configs
  <list of other commands and what they do>

Options:
BANNER

  opt :model, "Model to use", short: :m, type: :string, default: config["defaults-model"]
  opt :model_name, "Specific model name", short: :M, type: :string
  opt :in_place, "Overwrite file in place", short: :I, default: false
  opt :input, "Input file (stdin if none given)", short: :i, type: :string
  opt :output, "Input file (stdout if none given)", short: :o, type: :string
  opt :debug, "Print debug info", short: :d, default: false
  opt :verbose, "Verbose output", short: :v, default: false
  # DESIGN: What other things do we need? If they are optional or configurable, add their options here.

  conflicts :model, :model_name
  conflicts :output, :in_place
end
```


Stdin/stdout work, or filenames:

`cat her_story.md | storyfix gender Tyrian he/him > his_story.md`
`storyfix -i her_story.md -o his_story.md gender Tyrian he/him`

## Help

`storyfix` without args is the same as `storyfix --help`.

Optimist help banner should also list commands: list, add, show, remove,
set-config, get-config, list-config, etc

## storyfix.db

TODO: Where?
TODO: Can we store the openrouter api in the OS keychain?

Tables:

fixes (id pkey, name varchar 255 unique, description varchar 255, body text);
settings (id pkey, key varchar 255 unique, value text);

## Configuration

Configuration goes in the settings table, which is a key/value store of key VARCHAR(255),
value VARCHAR(255). key is unique.

Config Commands:
* set-config key <value>
* get-config key
* list-configs # ORDER BY name ASC

Many configs have CLI options. Options take precedence over configuration
settings and ENV vars:

`options = config_options.merge(env_options).merge(command_line_options)`

## Installed Configuration Values

model-opus: anthropic/claude-opus-4.6
model-sonnet: anthropic/claude-sonnet-4.6
model-haiku: anthropic/claude-haiku-4.5
...continue with current openrouter models from grok, deepseek, chatgpt, perplexity, gemini

## OpenRouter API Key

I'm torn on where to store this. It's a local app, not a service. We can allow
it in the database but lets at least write a warning in the docs that the key
should probably have a spend limit on it.

TODO: Can we store it in the user's keychain?

## API Call
Use the provider's HTTP API directly. No SDK gem needed — it's one POST request with a JSON body. Use `net/http`.

**Request shape (OpenRouter example):**
```
POST https://openrouter.ai/api/v1/chat/completions
Authorization: Bearer #{OPENROUTER_API_KEY}

{
  "model": "anthropic/claude-sonnet-4-20250514",
  "messages": [
    {"role": "system", "content": "<system prompt>"},
    {"role": "user", "content": "<file contents>"}
  ]
}
```

**Response:** Extract `choices[0].message.content` — that's the corrected text.

## Error Handling
- Missing API key → clear error message naming the env var or config field needed
- API error (rate limit, server error) → print the status code and error body, exit nonzero
- Empty response → error, do not silently output nothing (especially with `--in-place`!)
- Network timeout → error, suggest retry

## The System Prompt

System prompts will be stored in the database. For now just one record, named
"fix", that basically says


```
You are a tightly-focused word-processing editor being asked to make a change to
textual content. Please fix the content, making ONLY the requested
change. Preserve the rest of the content verbatim. Only if the fix requests
wider discretion may other changes be made. Return NOTHING but the updated
story, this is being used in a text-editing tool that does not interpret your
response, anything you add or say will be inserted as a replacement for the
user's story.

This is an edit in extremely-limited scope. Unless the fix EXPLICITLY REQUESTS a
change,

* Do NOT rephrase, rewrite, "improve," or restructure anything
* Do NOT add or remove content
* Do NOT change intentional stylistic choices (fragments, informal language,
  dialect, etc.)

Return ONLY the corrected text — no commentary, no explanations, no markdown
wrapping.

The fix the user is requesting is: user has requested this fix: #{fix}
```

Also attach a system note:

```
CSAM handling rule: If the user's content contains sexual content involving
minors, do not engage with the content, but assume benign intent on the part of
the user and return as helpful a message as possible, e.g. "I'm sorry, I can't
work on this. Maria is listed here as being 14 and is involved in a sexual
situation." or "I'm sorry, I can't work on this. Peter is depicted in a sexual
situation and is strongly coded as a minor (elementary student)."
```

**This prompt will need iteration.** V1 ships with a reasonable prompt baked in. Future versions may allow custom prompts.

## File Structure

Standard ruby gem structure.

## Dependencies

- **Ruby** (4.x)
- **colorize** — terminal text output (red for errors, yellow for warnings, etc)
- **optimist** — CLI option parsing
- **net/http** — HTTP client for API calls
- **json** (stdlib) — API request/response

That's it. Keep it minimal.

## What Is NOT In Scope

- **Context window management** — The target is flash fiction and RP cards, rarely over 2k tokens. If your file is too big for the model's context window, that's your problem.
- **Idempotency** — Running the tool twice may produce slightly different results. The LLM is stochastic. That's fine.
- **Streaming** — Not needed. Wait for the full response.
- **Interactive mode** — No TUI, no prompts, no "accept this change?" flow. It's a batch tool.
- **Custom prompts** — v2. For now, the built-in prompt is the prompt.
- **Diff output** — v2.
- **Batch processing** — v2.
- **Direct Anthropic/OpenAI API support** — v2 maybe. OpenRouter covers it for v1.

## Success Criteria

1. `storyfix fix myfile.txt` outputs a corrected version of the file to stdout
2. `storyfix fix -i myfile.txt` overwrites the file with the corrected version
3. The corrected text has fewer typos/grammar errors than the input
4. The corrected text reads like the same author wrote it — no LLM "improvements"
5. Config merging works correctly (file < env < CLI)
6. Errors are clear and actionable

## Testing

RSpec.

Use clear English sentence descriptions in the spec name so that they read like
specifications. Be clear and specific in your it blocks, speaking the language
of the maintainer without summary or abstraction. Don't say "raises an error" or
"returns correct data". Say WHAT the error is or what the correct data is.
