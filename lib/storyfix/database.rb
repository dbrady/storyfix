require "extralite"
require "fileutils"

module Storyfix
  class Database
    attr_reader :db_path

    def initialize(db_path = default_db_path)
      @db_path = db_path
      @db = nil
    end

    def connection
      @db ||= begin
        ensure_directory!
        Extralite::Database.new(@db_path)
      end
    end

    def close
      if @db
        @db.close
        @db = nil
      end
    end

    def transaction(&block)
      connection.transaction(&block)
    end

    private

    def default_db_path
      config_dir = ENV['XDG_CONFIG_HOME'] || File.join(Dir.home, '.config')
      File.join(config_dir, 'storyfix', 'storyfix.db')
    end

    def ensure_directory!
      dir = File.dirname(@db_path)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
  end
end
