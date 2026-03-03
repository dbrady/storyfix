require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Migrator do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  let(:db) { Extralite::Database.new(db_path) }

  after do
    db.close
    FileUtils.remove_entry(tmp_dir)
  end

  describe ".needs_migration?" do
    it "returns true for an empty database" do
      expect(described_class.needs_migration?(db)).to be true
    end

    it "returns false after migration" do
      described_class.migrate!(db)
      expect(described_class.needs_migration?(db)).to be false
    end
  end

  describe ".migrate!" do
    it "applies the schema" do
      described_class.migrate!(db)
      tables = db.query_splat("SELECT name FROM sqlite_master WHERE type='table'")
      expect(tables).to include("fixes", "settings")
    end
  end

  describe ".seed_defaults" do
    it "inserts default settings" do
      described_class.migrate!(db)
      described_class.seed_defaults(db)
      
      model = db.query_single_splat("SELECT value FROM settings WHERE key='model-gpt4'")
      expect(model).to eq("openai/gpt-4o")
    end
    
    it "does not overwrite existing settings" do
      described_class.migrate!(db)
      db.execute("INSERT INTO settings (key, value) VALUES ('model-gpt4', 'custom/model')")
      
      described_class.seed_defaults(db)
      
      model = db.query_single_splat("SELECT value FROM settings WHERE key='model-gpt4'")
      expect(model).to eq("custom/model")
    end
  end

  describe ".auto_initialize" do
    it "migrates and seeds in one step" do
      described_class.auto_initialize(db)
      version = db.query_single_splat("SELECT version FROM schema_info")
      expect(version).to eq(1)
      
      model = db.query_single_splat("SELECT value FROM settings WHERE key='default-model'")
      expect(model).not_to be_nil
    end
  end
end
