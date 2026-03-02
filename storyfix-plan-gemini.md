# StoryFix Master Plan (Gemini)

## Part 1: Settled Architecture & Design Decisions

These initial questions from the PRD have been resolved:

*   **Database Location:** Follow XDG Base Directory Specification. The database will live at `~/.config/storyfix/storyfix.db`. This is standard for Linux/macOS CLI tools.
*   **API Key Storage:** For v1, rely on the `OPENROUTER_API_KEY` environment variable or storing it in the SQLite `settings` table. We will add a prominent warning in the docs regarding API key spend limits. Integration with the OS keychain is deferred to v2 to minimize dependencies.
*   **Command vs. Fix Name Routing:** We will maintain a list of reserved keywords (`list`, `add`, `remove`, `show`, `get-config`, `set-config`, `list-configs`). The `add` command will reject any attempt to create a fix with a reserved name.
*   **Argument Interpolation Syntax:** Fix bodies will use mustache-style templating for positional arguments: `{{1}}`, `{{2}}`, etc. The execution engine will inject `ARGV[0]`, `ARGV[1]`, etc., into those slots before sending the prompt to the LLM.
*   **Auto-Initialization (Seeding the DB):** On every run, the CLI will perform a bootstrap check. If `~/.config/storyfix/storyfix.db` does not exist, it will create the directory, initialize the schema, and insert the default configuration values and the baked-in v1 system prompt.
*   **I/O State Conflicts:** Added validation logic: if `--in_place` (or `-I`) is true, an `--input` (or `-i`) file *must* be provided and must be a valid, existing file path. `--in_place` strictly conflicts with `stdin`.

## Part 2: Master Execution Plan

This is the phased execution strategy for the project, adhering strictly to the 100% test coverage rule and Ruby 3.3 compatibility.

### Phase 1: Foundation & Tooling
*   **1.1 Scaffolding:** Generate the standard Ruby gem structure (`lib`, `bin`, `spec`, `storyfix.gemspec`). Ensure Ruby 3.3 requirement.
*   **1.2 Dependencies:** Setup Bundler. Add `optimist`, `colorize`, and `extralite` as runtime dependencies. Add `rspec`, `simplecov`, and `webmock` as development dependencies.
*   **1.3 Test Harness:** Configure RSpec. Configure SimpleCov to enforce a strict 100% line and branch coverage threshold, causing the build to fail if it drops below.

### Phase 2: Local Database & Initialization
*   **2.1 Extralite Wrapper:** Implement `Storyfix::Database` to handle the SQLite connection to `~/.config/storyfix/storyfix.db`. Ensure thread safety or appropriate connection handling if needed (though mostly sequential in CLI).
*   **2.2 Schema & Seeding:** Implement the auto-initialization routine to create the `fixes` and `settings` tables, and seed the default models and v1 system prompt if they are missing.

### Phase 3: Configuration Management
*   **3.1 Settings Model:** Implement CRUD operations for the `settings` table.
*   **3.2 Config CLI:** Wire up Optimist to handle `set-config`, `get-config`, and `list-configs` commands.
*   **3.3 Config Merger:** Implement the resolution logic that prioritizes settings: `Database < Environment Variables < CLI Options`.

### Phase 4: Fixes (Prompt) Management
*   **4.1 Fix Model:** Implement CRUD operations for the `fixes` table. Add validation to reject reserved command names.
*   **4.2 Fix CLI:** Wire up Optimist for the `list`, `add`, `show`, and `remove` commands.
*   **4.3 Prompt Builder:** Implement the logic that retrieves a fix, interpolates positional CLI arguments (`{{1}}`, `{{2}}`, etc.) into the fix body, and constructs the final JSON payload for the LLM.

### Phase 5: Core API Client
*   **5.1 OpenRouter Client:** Build `Storyfix::Client` using Ruby's built-in `net/http` and `json`.
*   **5.2 Error Handling:** Implement robust rescue blocks for missing API keys, OpenRouter HTTP errors (rate limits, 500s), empty responses, and network timeouts. Use `colorize` to emit clear, actionable terminal errors (e.g., red for errors, yellow for warnings).

### Phase 6: I/O and Main Execution Loop
*   **6.1 Optimist Parsing:** Build `bin/storyfix`. Define global flags (`--model`, `--in_place`, `--input`, etc.) and the main command router.
*   **6.2 I/O Handlers:** Implement stream management. Detect if `stdin` has data. Route data correctly depending on whether `--input`, `--output`, or `--in_place` are used. Handle reading the entire input before processing.
*   **6.3 Integration:** Connect the I/O, the Config Manager, the Prompt Builder, and the API Client to execute the end-to-end `fix` execution flow.

### Phase 7: Quality Assurance & Polish
*   **7.1 CI / Quality Check:** Ensure all RSpec tests follow the PRD's linguistic guidelines (clear English specifications). Validate that SimpleCov is reporting 100%. Ensure tests use `webmock` to prevent actual API calls.
*   **7.2 Documentation:** Write a clear `README.md` containing installation steps, configuration examples, the interpolation syntax (`{{1}}`), and the API key spend limit warning.
