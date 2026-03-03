require_relative "schema"

module Storyfix
  class Migrator
    def self.needs_migration?(db)
      begin
        version = db.query_single_splat("SELECT version FROM schema_info")
        version.nil? || version < Schema::SCHEMA_VERSION
      rescue Extralite::SQLError
        true
      end
    end

    def self.migrate!(db)
      if needs_migration?(db)
        db.transaction do
          Schema.apply(db)
        end
      end
    end

    SYSTEM_PROMPT = <<~PROMPT.chomp
      You are a highly capable text editing assistant. Apply the following fix to the user's text. Important: you are performing an in-place edit! Do not add commentary, do not say what you are doing--it will be injected into the story! If you have confusion or struggle, just do your best--if you are unable to perform the task, simply return the original text verbatim. DO NOT EMIT PREAMBLE such as "Here is the updated document" or "I have updated your changes".
    PROMPT

    def self.seed_defaults(db)
      defaults = {
        "default-model" => "anthropic/claude-3.5-haiku",
        "model-opus" => "anthropic/claude-3-opus",
        "model-sonnet" => "anthropic/claude-3.5-sonnet",
        "model-haiku" => "anthropic/claude-3.5-haiku",
        "model-gpt4" => "openai/gpt-4o",
        "model-gemini" => "google/gemini-pro-1.5",
        "model-deepseek" => "deepseek/deepseek-chat",
        "model-grok" => "xai/grok-2",
        "api-timeout" => "60",
        "system-prompt-fix" => SYSTEM_PROMPT
      }

      db.transaction do
        defaults.each do |key, value|
          db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", key, value)
        end
      end
    end

    def self.seed_default_fixes(db)
      fixes = [
        {
          name: "tense",
          description: "Narrator verb tense",
          body: "Please change the narrator's verb tense to {{1}}."
        },
        {
          name: "gender",
          description: "Set character's gender",
          body: "Please change {{1}}'s gender to {{2}}. Update any and all pronouns and titles (e.g. landlord/landlady, queen/king, master/mistress). If the subject is female and the new gender is nonbinary, use neutral or masculine titles, e.g. Queen/Monarch, Dame/Duke."
        },
        {
          name: "novel-big",
          description: "Novelization rewrite (big rewrites)",
          body: "Please rewrite this story as faithfully as possible to the spirit of the original, but write in clean, modern English novelization format. This is not a verbatim rewrite. YOU MAY ADD VERBIAGE. Keep a clean, emotive novelization flow. Don't be overly florid, awkward, or cerebral. Ground characters in the reality of the story."
        },
        {
          name: "fix",
          description: "Arbitrary fix (must specify)",
          body: "{{1}}"
        }
      ]

      db.transaction do
        fixes.each do |fix|
          db.execute(
            "INSERT OR IGNORE INTO fixes (name, description, body) VALUES (?, ?, ?)",
            fix[:name], fix[:description], fix[:body]
          )
        end
      end
    end

    def self.auto_initialize(db)
      migrate!(db)
      seed_defaults(db)
      seed_default_fixes(db)
    end
  end
end
