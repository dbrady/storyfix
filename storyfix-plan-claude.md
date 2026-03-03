# StoryFix Implementation Plan

## Overview

This document contains the complete implementation plan for StoryFix, a Ruby CLI tool that transforms text using LLMs via OpenRouter.

---

## Resolved Decisions

These items were ambiguous or marked TODO in the PRD. Resolutions are documented here.

| Decision | Resolution |
|----------|------------|
| Ruby version | **Ruby 3.3** (avoids LLM training cutoff issues with Ruby 4 syntax) |
| Database location | `~/.config/storyfix/storyfix.db` (XDG-compliant) |
| API key storage | `OPENROUTER_API_KEY` env var primary; `api-key` in settings table as fallback. Docs warn about spend limits. Keychain deferred to v2. |
| Fix interpolation syntax | `{{1}}`, `{{2}}`, etc. (simple positional, no dependencies) |
| Missing fix arguments | **Error** — "Fix 'gender' expects 2 arguments, got 1" (prevents destructive empty substitutions) |
| Extra fix arguments | **Error** — "Fix 'gender' expects 2 arguments, got 3" (likely a forgotten quote) |
| --in_place + stdin | **Conflict** — --in_place requires --input file, cannot use stdin |
| CSAM/refusal handling | Document as known v1 limitation. LLM may overwrite file with refusal text. v2 may add [FAILED] tag detection. |
| Reserved command names | `list`, `add`, `remove`, `show`, `get-config`, `set-config`, `list-configs`, `help`, `version`. Fix creation with these names is rejected with clear error. |
| Script architecture | Single `bin/storyfix` binary with internal command routing |
| System prompt storage | `settings` table, key `system-prompt-fix` |
| Default model config | Key `default-model` holds alias (e.g., `sonnet`), which resolves via `model-sonnet` → full model string |
| Exit codes | 0=success, 1=usage/general error, 2=API error, 3=config error |
| Timeout | 120 seconds default, configurable via `api-timeout` setting |
| --verbose output | Progress messages: "Reading input...", "Calling API...", "Writing output..." |
| --debug output | Everything from --verbose plus full request/response dumps |
| SQLite gem | `extralite` (add to Dependencies section of PRD) |
| Default fixes | Ship empty; user creates their own |
| First-run behavior | Auto-create database with default settings, no wizard |

---

## Default Configuration Seeds

These values are inserted on first run:

```
default-model: sonnet
api-timeout: 120

model-opus: anthropic/claude-opus-4.6
model-sonnet: anthropic/claude-sonnet-4.6
model-haiku: anthropic/claude-haiku-4.5
model-gpt4: openai/gpt-4
model-gemini: google/gemini-2.5-pro
model-deepseek: deepseek/deepseek-v3.2
model-grok: x-ai/grok-4
model-perplexity: perplexity/sonar-pro

system-prompt-fix: <full prompt from PRD>
```

Note: Model strings verified against OpenRouter models list on 2026-03-03; refresh if OpenRouter updates IDs.

---

## Phase 0: Pre-Implementation

### 0.1 Update PRD
- Change line 27 from "Fixes are storyfix-<command>" to "storyfix <command>"
- Change Ruby version references from 4.x to 3.3
- Add extralite to Dependencies section

### 0.2 Verify OpenRouter Model Strings
- Research current model identifiers for: Claude, GPT-4, Gemini, DeepSeek, Grok, Perplexity
- Document in seeds

---

## Phase 1: Project Scaffolding

### 1.1 Create directory structure
```
storyfix/
├── bin/
│   └── storyfix
├── lib/
│   ├── storyfix.rb
│   └── storyfix/
│       └── version.rb
├── spec/
│   └── spec_helper.rb
├── Gemfile
├── Rakefile
├── storyfix.gemspec
├── .rspec
└── README.md
```

### 1.2 Create Gemfile
```ruby
source 'https://rubygems.org'

ruby '~> 3.3'

gemspec

group :development, :test do
  gem 'rspec', '~> 3.12'
  gem 'simplecov', require: false
end
```

### 1.3 Create storyfix.gemspec
- Name: storyfix
- Version: require from lib/storyfix/version.rb
- Dependencies: optimist, colorize, extralite

### 1.4 Create lib/storyfix/version.rb
```ruby
module Storyfix
  VERSION = "0.1.0"
end
```

### 1.5 Create lib/storyfix.rb
- Require all submodules
- Module namespace

### 1.6 Create bin/storyfix
- Shebang: #!/usr/bin/env ruby
- Require storyfix
- Call Storyfix::CLI.run(ARGV)

### 1.7 Create spec/spec_helper.rb
- Require simplecov with minimum_coverage 100
- Require storyfix

### 1.8 Create Rakefile
- Default task: spec

### 1.9 Create .rspec
```
--format documentation
--color
--require spec_helper
```

### 1.10 Verify setup
- `bundle install` succeeds
- `bundle exec rspec` runs (empty suite)

---

## Phase 2: Database Layer

### 2.1 Create lib/storyfix/database.rb

```ruby
module Storyfix
  module Database
    def self.db_path
      # ~/.config/storyfix/storyfix.db
    end

    def self.connection
      # Lazy, cached connection
    end

    def self.ensure_directory!
      # Create ~/.config/storyfix if missing
    end

    def self.close
      # Close connection if open
    end
  end
end
```

### 2.2 Create lib/storyfix/schema.rb

Tables:
```sql
CREATE TABLE IF NOT EXISTS fixes (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  description VARCHAR(255),
  body TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY,
  key VARCHAR(255) UNIQUE NOT NULL,
  value TEXT
);

CREATE TABLE IF NOT EXISTS schema_info (
  version INTEGER NOT NULL
);
```

### 2.3 Create lib/storyfix/migrator.rb
- Check schema version
- Run migrations if needed
- Seed defaults on fresh install

### 2.4 Write specs
- spec/storyfix/database_spec.rb
- spec/storyfix/schema_spec.rb
- spec/storyfix/migrator_spec.rb

---

## Phase 3: Settings

### 3.1 Create lib/storyfix/setting.rb

```ruby
module Storyfix
  class Setting
    def self.get(key)
    def self.set(key, value)
    def self.delete(key)
    def self.all
    def self.exists?(key)
  end
end
```

### 3.2 Create lib/storyfix/config.rb

```ruby
module Storyfix
  class Config
    # Merge priority: settings < env < CLI
    def self.resolve(key, cli_value: nil, env_key: nil)

    # Resolve model alias to full string
    def self.model_for(alias_or_full)

    # Get API key (env first, then settings)
    def self.api_key

    # Get system prompt
    def self.system_prompt
  end
end
```

### 3.3 Implement commands
- get-config: Print value for key, error if not found
- set-config: Set key=value, create or update
- list-configs: Print all settings, sorted by key

### 3.4 Write specs
- spec/storyfix/setting_spec.rb
- spec/storyfix/config_spec.rb

---

## Phase 4: Fixes

### 4.1 Create lib/storyfix/fix.rb

```ruby
module Storyfix
  class Fix
    RESERVED_NAMES = %w[
      list add remove show
      get-config set-config list-configs
      help version
    ].freeze

    attr_reader :id, :name, :description, :body

    def self.find(name)
    def self.all
    def self.create(name, description, body)
    def self.delete(name)

    def render(args)
      # Replace {{1}}, {{2}}, etc. with args
    end

    private

    def self.validate_name!(name)
      # Reject reserved names
    end
  end
end
```

### 4.2 Implement commands
- list: Print all fixes (name, description)
- add: Create fix, validate name not reserved
- show: Print fix details (name, description, body)
- remove: Delete fix by name

### 4.3 Write specs
- spec/storyfix/fix_spec.rb
  - CRUD operations
  - Interpolation with 0, 1, 2, 3 args
  - Reserved name rejection
  - Nonexistent fix handling

---

## Phase 5: CLI Framework

### 5.1 Create lib/storyfix/cli.rb

```ruby
module Storyfix
  class CLI
    def self.run(argv)

    private

    def self.parse_options(argv)
      # Optimist setup from PRD
    end

    def self.route_command(command, args, opts)
      # Dispatch to appropriate handler
    end
  end
end
```

### 5.2 Create lib/storyfix/io_handler.rb

```ruby
module Storyfix
  class IOHandler
    def self.read_input(opts)
      # stdin if no --input, else read file
    end

    def self.write_output(opts, content)
      # stdout if no --output/--in-place
      # file if --output
      # overwrite if --in-place
    end

    def self.validate_input!(content)
      # Error if empty
    end
  end
end
```

### 5.3 Behaviors
- No args → show help (same as --help)
- --version → print version
- Unknown command → error with suggestions

### 5.4 Write specs
- spec/storyfix/cli_spec.rb
- spec/storyfix/io_handler_spec.rb

---

## Phase 6: API Client

### 6.1 Create lib/storyfix/errors.rb

```ruby
module Storyfix
  class Error < StandardError; end
  class MissingApiKeyError < Error; end
  class ApiError < Error
    attr_reader :status, :body
  end
  class EmptyResponseError < Error; end
  class TimeoutError < Error; end
end
```

### 6.2 Create lib/storyfix/api_client.rb

```ruby
module Storyfix
  class ApiClient
    ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"

    def initialize(api_key:, model:, timeout: 120)

    def call(system_prompt:, user_content:)
      # POST request
      # Parse response
      # Return choices[0].message.content
      # Raise appropriate errors
    end
  end
end
```

### 6.3 Error handling
- Missing API key → MissingApiKeyError with message naming OPENROUTER_API_KEY and api-key setting
- 4xx/5xx → ApiError with status and body
- Empty choices or content → EmptyResponseError
- Net::ReadTimeout → TimeoutError with retry suggestion

### 6.4 Write specs
- spec/storyfix/api_client_spec.rb (use webmock)
- spec/storyfix/errors_spec.rb

---

## Phase 7: Fix Execution

### 7.1 Create lib/storyfix/executor.rb

```ruby
module Storyfix
  class Executor
    def initialize(opts)
      @opts = opts
    end

    def run(fix_name, fix_args)
      # 1. Find fix
      # 2. Render fix body with args
      # 3. Compose system prompt
      # 4. Read input
      # 5. Call API
      # 6. Write output
    end

    private

    def compose_system_prompt(rendered_fix)
      # Base prompt from settings
      # Interpolate fix
      # Append CSAM note
    end
  end
end
```

### 7.2 Debug/verbose output
- --verbose: Progress messages to stderr
- --debug: Request/response dumps to stderr

### 7.3 Write specs
- spec/storyfix/executor_spec.rb

---

## Phase 8: Output Formatting

### 8.1 Create lib/storyfix/output.rb

```ruby
module Storyfix
  module Output
    def self.error(msg)    # red, to stderr
    def self.warn(msg)     # yellow, to stderr
    def self.info(msg)     # cyan, to stderr (verbose)
    def self.debug(msg)    # dim, to stderr (debug)
    def self.success(msg)  # green, to stderr
  end
end
```

### 8.2 Standardize all error messages
- Consistent format: "storyfix: error: <message>"
- Actionable suggestions where applicable

### 8.3 Write specs
- spec/storyfix/output_spec.rb

---

## Phase 9: Integration Testing

### 9.1 Create spec/integration/ directory

### 9.2 CLI integration tests
- Invoke `bin/storyfix` as subprocess
- Capture stdout, stderr, exit code

### 9.3 Test scenarios
- list/add/show/remove cycle
- get-config/set-config/list-configs cycle
- Fix execution with mocked API (webmock)
- All error conditions produce correct exit codes
- stdin/stdout mode
- File input/output mode
- --in-place mode

### 9.4 Coverage verification
- SimpleCov must report 100%

---

## Phase 10: Documentation & Packaging

### 10.1 README.md
- What StoryFix does
- Installation
  - `gem install storyfix`
  - `git clone && bundle install`
- Quick start example
- Configuration
  - API key setup (with spend limit warning)
  - Default model
  - Settings commands
- Creating and using fixes
- CLI reference (all commands and options)
- Troubleshooting

### 10.2 CHANGELOG.md
- v0.1.0 initial release

### 10.3 Verify gemspec
- All metadata filled in
- Files list correct

### 10.4 Test installation
- `gem build storyfix.gemspec`
- `gem install ./storyfix-0.1.0.gem`
- Verify commands work

### 10.5 Test git clone installation
- Fresh clone
- `bundle install`
- `bin/storyfix --help`

### 10.6 Optional: CI
- `.github/workflows/test.yml`
- Run specs on push/PR

---

## Task Dependency Graph

```
Phase 1 (scaffolding)
    │
    ▼
Phase 2 (database)
    │
    ├──────────────┬──────────────┐
    ▼              ▼              ▼
Phase 3        Phase 4        Phase 6
(settings)     (fixes)        (API client)
    │              │              │
    └──────────────┴──────────────┘
                   │
                   ▼
              Phase 5 (CLI)
                   │
                   ▼
              Phase 7 (executor)
                   │
                   ▼
              Phase 8 (output)
                   │
                   ▼
              Phase 9 (integration tests)
                   │
                   ▼
              Phase 10 (docs & packaging)
```

Phases 3, 4, and 6 can be developed in parallel after Phase 2.

---

## Task Summary

| Phase | Description | Task Count |
|-------|-------------|------------|
| 0 | Pre-implementation | 2 |
| 1 | Scaffolding | 10 |
| 2 | Database | 7 |
| 3 | Settings | 8 |
| 4 | Fixes | 8 |
| 5 | CLI | 9 |
| 6 | API Client | 9 |
| 7 | Executor | 6 |
| 8 | Output | 4 |
| 9 | Integration Tests | 10 |
| 10 | Docs & Packaging | 7 |
| **Total** | | **~80** |

---

## Open Questions for User

None at this time. All ambiguities have been resolved.
