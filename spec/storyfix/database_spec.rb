require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Storyfix::Database do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  
  after do
    FileUtils.remove_entry(tmp_dir)
  end

  it "resolves to XDG_CONFIG_HOME or ~/.config by default" do
    old_xdg = ENV['XDG_CONFIG_HOME']
    ENV['XDG_CONFIG_HOME'] = '/fake/config'
    
    db = described_class.new
    expect(db.db_path).to eq("/fake/config/storyfix/storyfix.db")
    
    ENV['XDG_CONFIG_HOME'] = old_xdg
  end

  it "creates the directory lazily on first connection" do
    custom_dir = File.join(tmp_dir, "custom_dir")
    custom_db_path = File.join(custom_dir, "test.db")
    db = described_class.new(custom_db_path)
    
    expect(Dir.exist?(custom_dir)).to be false
    
    conn = db.connection
    expect(Dir.exist?(custom_dir)).to be true
    expect(File.exist?(custom_db_path)).to be true
    
    db.close
  end

  it "can connect and close" do
    db = described_class.new(db_path)
    expect(db.connection).to be_a(Extralite::Database)
    expect { db.close }.not_to raise_error
  end

  it "can close multiple times without error" do
    db = described_class.new(db_path)
    db.connection
    db.close
    expect { db.close }.not_to raise_error
  end

  it "supports transactions" do
    db = described_class.new(db_path)
    Storyfix::Schema.apply(db.connection)

    db.transaction do
      db.connection.execute("INSERT INTO settings (key, value) VALUES ('test', 'val')")
    end

    result = db.connection.query_single_splat("SELECT value FROM settings WHERE key = 'test'")
    expect(result).to eq("val")
    db.close
  end
end
