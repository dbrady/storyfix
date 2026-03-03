require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Setting do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  let(:db) { Extralite::Database.new(db_path) }
  let(:setting) { described_class.new(db) }

  before do
    Storyfix::Schema.apply(db)
  end

  after do
    db.close
    FileUtils.remove_entry(tmp_dir)
  end

  it "can get and set values" do
    setting.set("test-key", "test-val")
    expect(setting.get("test-key")).to eq("test-val")
  end

  it "updates existing values" do
    setting.set("test-key", "test-val")
    setting.set("test-key", "new-val")
    expect(setting.get("test-key")).to eq("new-val")
  end

  it "can check if a key exists" do
    expect(setting.exists?("missing")).to be false
    setting.set("missing", "here")
    expect(setting.exists?("missing")).to be true
  end

  it "can delete values" do
    setting.set("delete-me", "value")
    setting.delete("delete-me")
    expect(setting.exists?("delete-me")).to be false
  end

  it "can return all settings as a hash" do
    setting.set("a", "1")
    setting.set("c", "3")
    setting.set("b", "2")
    
    expect(setting.all).to eq({
      "a" => "1",
      "b" => "2",
      "c" => "3"
    })
  end
end
