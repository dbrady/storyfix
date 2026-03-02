# StoryFix Master Plan (Codex)

Date context: March 2, 2026. Target Ruby is 3.3.x.

## Confirmed Decisions
- Ruby version is 3.3.x.
- CLI grammar is `storyfix <fix> [args]`.
- No positional file argument. Input is stdin or `--input`.
- Fix placeholder syntax is `{{1}}`, `{{2}}`, etc.
- Fixes are added with quoted strings only.
- SQLite library is `extralite`.
- No config file. Precedence is `db < env < cli`.
- HTTP timeout target is 120 seconds.
- Use WebMock for HTTP tests.

## Open Decisions
- Database location policy and override mechanism.
- Keychain support feasibility on macOS and Linux, plus the chosen implementation.
- Final list of default model aliases. The PRD lists three and implies more.
- Exact behavior for missing or extra fix arguments when substituting `{{n}}`.
- Resolve remaining doc conflicts around `storyfix-<command>` and in-place flag examples.

## Master Plan
1. Update PRD for Ruby 3.3.x and remove any Ruby 4 references.
2. Resolve and document DB location policy. Decide default path and override env var or CLI flag.
3. Investigate keychain support for macOS and Linux in Ruby. Choose an approach or document fallback behavior.
4. Decide final default model alias list or explicitly require user-specified models.
5. Define placeholder substitution rules. Specify behavior for missing or extra args and escaping rules.
6. Resolve doc conflicts. Align success criteria and examples with `--input`, `--output`, and `--in-place`.
7. Scaffold the gem. Add gemspec, `bin/storyfix`, `lib/`, `.ruby-version` set to 3.3, and bundler setup.
8. Implement DB layer with `extralite`. Create schema, connection handling, and CRUD for fixes and settings.
9. Implement config loader. Merge DB settings, env vars, and CLI options with the documented precedence.
10. Implement CLI parsing with Optimist. Support commands: `list`, `add`, `remove`, `show`, `get-config`, `set-config`, `list-configs`, and main fix invocation.
11. Implement prompt assembly. Build system prompt and inject fix text with placeholder substitutions.
12. Implement OpenRouter client. Use `net/http`, set 120s timeouts, and include required headers from documentation.
13. Implement core pipeline. Read input, call LLM, validate output, and write to stdout or overwrite input when `--in-place` is set.
14. Implement error handling. Missing API key, missing fix, empty input, empty response, network errors, and filesystem errors should have clear messages and nonzero exit codes.
15. Add RSpec + SimpleCov setup. Ensure 100% coverage with targeted unit and integration specs.
16. Add CLI tests for option conflicts and command behavior.
17. Add README and usage docs. Include install, API key guidance, warnings, and examples.
18. Verify packaging readiness. `bundle exec rspec` must be green and gem metadata correct.
