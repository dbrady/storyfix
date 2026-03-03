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

  describe ".seed_default_fixes" do
    it "inserts default fixes" do
      Storyfix::Migrator.migrate!(db)

      Storyfix::Migrator.seed_default_fixes(db)

      fix = db.query_single("SELECT name, description FROM fixes WHERE name='tense'")
      expect(fix[:name]).to eq("tense")
      expect(fix[:description]).to eq("Narrator verb tense")
    end

    it "does not overwrite existing fixes" do
      Storyfix::Migrator.migrate!(db)
      db.execute("INSERT INTO fixes (name, description, body) VALUES ('tense', 'Custom', 'Custom body')")

      Storyfix::Migrator.seed_default_fixes(db)

      fix = db.query_single("SELECT description FROM fixes WHERE name='tense'")
      expect(fix[:description]).to eq("Custom")
    end
  end

  describe ".auto_initialize" do
    it "migrates and seeds settings and fixes" do
      Storyfix::Migrator.auto_initialize(db)

      version = db.query_single_splat("SELECT version FROM schema_info")
      expect(version).to eq(1)

      model = db.query_single_splat("SELECT value FROM settings WHERE key='default-model'")
      expect(model).not_to be_nil

      fix_count = db.query_single_splat("SELECT COUNT(*) FROM fixes")
      expect(fix_count).to be >= 4
    end
  end
end
