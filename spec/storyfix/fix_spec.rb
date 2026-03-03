require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Fix do
  describe "#render" do
    it "renders without arguments" do
      fix = described_class.new(name: "test", description: "desc", body: "Fix this.")
      expect(fix.render).to eq("Fix this.")
    end

    it "interpolates positional arguments" do
      fix = described_class.new(name: "test", description: "desc", body: "Change {{1}} to {{2}}.")
      expect(fix.render(["he", "she"])).to eq("Change he to she.")
    end

    it "raises error if missing arguments" do
      fix = described_class.new(name: "test", description: "desc", body: "Change {{1}} to {{2}}.")
      expect { fix.render(["he"]) }.to raise_error(ArgumentError, /requires exactly 2 arguments, but got 1/)
    end

    it "raises error if extra arguments" do
      fix = described_class.new(name: "test", description: "desc", body: "Change {{1}}.")
      expect { fix.render(["he", "extra"]) }.to raise_error(ArgumentError, /requires exactly 1 arguments, but got 2/)
    end
  end

  describe Storyfix::Fix::Store do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:db_path) { File.join(tmp_dir, "test.db") }
    let(:db) { Extralite::Database.new(db_path) }
    let(:store) { described_class.new(db) }

    before do
      Storyfix::Schema.apply(db)
    end

    after do
      db.close
      FileUtils.remove_entry(tmp_dir)
    end

    it "can create and find fixes" do
      store.create(name: "tense", description: "Change to past tense", body: "Make this past tense.")
      fix = store.find("tense")
      
      expect(fix).not_to be_nil
      expect(fix.name).to eq("tense")
      expect(fix.description).to eq("Change to past tense")
      expect(fix.body).to eq("Make this past tense.")
    end

    it "rejects reserved names" do
      expect {
        store.create(name: "add", description: "desc", body: "body")
      }.to raise_error(ArgumentError, /reserved name/)
      
      expect(store.find("add")).to be_nil
    end

    it "returns all fixes" do
      store.create(name: "b", description: "b desc", body: "b body")
      store.create(name: "a", description: "a desc", body: "a body")
      
      fixes = store.all
      expect(fixes.length).to eq(2)
      expect(fixes.first.name).to eq("a")
      expect(fixes.last.name).to eq("b")
    end

    it "can delete fixes" do
      store.create(name: "del", description: "desc", body: "body")
      expect(store.find("del")).not_to be_nil
      
      store.delete("del")
      expect(store.find("del")).to be_nil
    end
  end
end
