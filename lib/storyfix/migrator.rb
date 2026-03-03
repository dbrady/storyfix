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
        "system-prompt-fix" => "You are a highly capable text editing assistant. Apply the following fix to the user's text."
      }

      db.transaction do
        defaults.each do |key, value|
          db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", key, value)
        end
      end
    end

    def self.auto_initialize(db)
      migrate!(db)
      seed_defaults(db)
    end
  end
end
