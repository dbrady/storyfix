module Storyfix
  module Schema
    SCHEMA_VERSION = 1

    def self.apply(db)
      db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS schema_info (
          version INTEGER PRIMARY KEY
        );
      SQL

      current_version = db.query_single_splat("SELECT version FROM schema_info") || 0

      if current_version < 1
        db.execute(<<~SQL)
          CREATE TABLE fixes (
            name TEXT PRIMARY KEY,
            description TEXT,
            body TEXT NOT NULL
          );

          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          );

          INSERT INTO schema_info (version) VALUES (1);
        SQL
      end
    end
  end
end
