require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Schema do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  let(:db) { Extralite::Database.new(db_path) }

  after do
    db.close
    FileUtils.remove_entry(tmp_dir)
  end

  it "creates required tables and tracks schema version" do
    Storyfix::Schema.apply(db)

    tables = db.query_splat("SELECT name FROM sqlite_master WHERE type='table'")
    expect(tables).to include("schema_info", "fixes", "settings")

    version = db.query_single_splat("SELECT version FROM schema_info")
    expect(version).to eq(1)
  end

  it "is idempotent when applied multiple times" do
    Storyfix::Schema.apply(db)
    expect { Storyfix::Schema.apply(db) }.not_to raise_error

    version = db.query_single_splat("SELECT version FROM schema_info")
    expect(version).to eq(1)
  end
end
