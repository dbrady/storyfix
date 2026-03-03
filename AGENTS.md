# AGENTS.md

> Guidelines for AI coding agents working in this Ruby codebase.

## RULE 0 - THE FUNDAMENTAL OVERRIDE PREROGATIVE

If the user tells you to do something, even if it goes against what follows below, YOU MUST LISTEN TO THEM.

## RULE NUMBER 1: NO FILE DELETION

Agents cannot delete files without explicit written permission. There's a horrible track record of deleting critically important files.

## Irreversible Git & Filesystem Actions

Forbidden commands include `git reset --hard`, `git clean -fd`, `rm -rf`, and **any operation on `.beads/issues.jsonl`** (read, edit, restore, etc.). Before executing destructive operations, agents must:
- Stop if uncertain about consequences
- Seek non-destructive alternatives first
- State the command verbatim with affected items
- Wait for explicit confirmation
- Document the authorization afterward

## Git Branch: ONLY Use `main`

All work occurs on `main` branch.

## Toolchain: Ruby & Bundler

- Ruby version 3.3+
- Install deps: `bundle install`
- Run tests: `bundle exec rspec`
- Run specific test: `bundle exec rspec spec/path/to_spec.rb`
- Run with coverage: `COVERAGE=1 bundle exec rspec`
- Format: Use standard Ruby style (2-space indent, no trailing whitespace)

Key dependencies: optimist (CLI parsing), extralite (SQLite), colorize (terminal output), rspec (testing), simplecov (coverage).

## Code Editing Discipline

Never run scripts that process code files. Always make changes manually. Avoid creating file variations like `main_v2.rb`. New files require incredibly high justification.

## Backwards Compatibility

We do not care about backwards compatibility—we're in early development with no users.

## Spec Checks (CRITICAL)

After substantive changes, verify: `bundle exec rspec`

All code must have 100% spec coverage. All commits require green specs.

## Testing

Use RSpec. Write clear English sentence descriptions so specs read like specifications. Be specific in `it` blocks—don't say "raises an error" or "returns correct data". Say WHAT the error is or what the correct data is.

Example:
```ruby
# Bad
it "raises an error" do

# Good
it "raises ArgumentError with message 'fix name cannot be blank'" do
```

Test files live in `spec/` mirroring the `lib/` structure.

## Logging & Console Output

Use `colorize` for terminal output. Red for errors, yellow for warnings, green for success.

## Third-Party Library Usage

If you aren't 100% sure how to use a third-party library, SEARCH ONLINE.

## StoryFix Project Overview

StoryFix is a Ruby CLI tool that transforms text using LLMs via OpenRouter. It applies "fixes" (stored prompts) to text content—changing pronouns, tense, POV, etc.

### Architecture

Text flows through: CLI parsing → fix lookup → system prompt assembly → OpenRouter API call → output

### Project Structure

```
storyfix/
├── bin/
│   └── storyfix          # CLI entry point
├── lib/
│   └── storyfix/
│       ├── version.rb
│       ├── cli.rb        # Optimist argument parsing
│       ├── config.rb     # Settings management
│       ├── database.rb   # SQLite via extralite
│       ├── fix.rb        # Fix model/operations
│       └── api.rb        # OpenRouter HTTP client
├── spec/
│   └── storyfix/
│       └── *_spec.rb
├── Gemfile
├── storyfix.gemspec
└── README.md
```

## MCP Agent Mail

Agent Mail provides identities, inbox/outbox, and file reservations. Register identity, reserve files before editing, and communicate via threads. Prefer macros (`macro_start_session`) when speed matters.

## Beads (br) — Issue Tracking

Beads provides dependency-aware task management. Key convention: use Beads ID (e.g., `storyfix-1iu`) as Mail thread ID. Run `br sync --flush-only` before git operations.

### DO NOT TOUCH `.beads/issues.jsonl`

**This file is managed exclusively by the `br` tool. NEVER:**
- Read it with cat/head/tail/Read
- Edit it with sed/awk/Edit/Write
- Run `git restore` on it
- Touch it in ANY way

**Why:** The `br` tool maintains internal state (hashes, caches, WAL) that WILL corrupt if the JSONL is modified externally. Other agents have caused data loss by ignoring this rule.

**Always use `br` commands** for ALL issue operations.

## Beads Workflow Integration

Essential commands:
- `br ready` — Show actionable work
- `br show <id>` — Full details
- `br update <id> --status=in_progress`
- `br close <id>`
- `br sync --flush-only` — Export to JSONL (no git)

Before ending: `br sync --flush-only` then manually commit.

## Landing the Plane (Session Completion)

Mandatory workflow when ending sessions:
1. File issues for remaining work
2. Run quality gates if code changed (`bundle exec rspec`)
3. Update issue status
4. Sync beads with `br sync --flush-only`
5. Provide handoff context
