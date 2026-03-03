module Storyfix
  class Setting
    def initialize(db)
      @db = db
    end

    def get(key)
      @db.query_single_splat("SELECT value FROM settings WHERE key = ?", key)
    end

    def set(key, value)
      @db.execute(<<~SQL, key, value, value)
        INSERT INTO settings (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = ?
      SQL
    end

    def delete(key)
      @db.execute("DELETE FROM settings WHERE key = ?", key)
    end

    def all
      @db.query("SELECT key, value FROM settings ORDER BY key ASC").to_h { |row| [row[:key], row[:value]] }
    end

    def exists?(key)
      !get(key).nil?
    end
  end
end
