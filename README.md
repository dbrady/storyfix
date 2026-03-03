# StoryFix

A simple CLI tool that applies pre-configured LLM "fixes" to text via OpenRouter.

## Installation

```bash
gem install storyfix
```
Or clone the repository and run:
```bash
bundle install
chmod +x bin/storyfix
```

## Quick Start

1. Set your OpenRouter API key:
   ```bash
   storyfix set-config api-key "sk-or-v1-..."
   ```
   Or use the `OPENROUTER_API_KEY` environment variable.

2. Create a fix (you can use `{{1}}`, `{{2}}` to interpolate arguments):
   ```bash
   storyfix add pov "Change point of view" "Rewrite the following text from the point of view of {{1}}."
   ```

3. Run the fix on a file and output to stdout:
   ```bash
   storyfix pov "a grumpy cat" -i input.txt
   ```

4. Overwrite the file in place:
   ```bash
   storyfix pov "a grumpy cat" -i input.txt -I
   ```

## Warning

**Cost Warning:** This tool makes calls to the OpenRouter API. Depending on the model you configure, this can incur significant costs. Monitor your API usage to avoid unexpected charges.

## Configuration

Settings are stored in `~/.config/storyfix/storyfix.db`.

```bash
storyfix set-config default-model anthropic/claude-3-haiku
storyfix get-config default-model
storyfix list-configs
```

### CSAM and Refusals
If the user request violates safety guidelines, the LLM may refuse the request cleanly. Using `--in-place` (`-I`) carries the risk of overwriting your input file with a refusal message or an empty response. Always keep a backup or use version control.
