require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Executor do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  let(:db) { Extralite::Database.new(db_path) }

  before do
    Storyfix::Schema.apply(db)
    Storyfix::Migrator.seed_defaults(db)
    db.execute("INSERT INTO fixes (name, description, body) VALUES ('FixSpelling', 'Corrects spelling', 'Fix {{1}}.')")
    db.execute("INSERT INTO settings (key, value) VALUES ('api-key', 'fake-key')")
  end

  after do
    db.close
    FileUtils.remove_entry(tmp_dir)
  end

  context "when executing a fix" do
    it "calls the API and outputs the result" do
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "input text")
      opts = { input: input_file, verbose: false, debug: false }
      executor = Storyfix::Executor.new(db: db, opts: opts)
      stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
        status: 200,
        body: { choices: [{ message: { content: "Fixed text." } }] }.to_json
      )

      expect { executor.run("FixSpelling", ["errors"]) }.to output("Fixed text.").to_stdout
    end
  end

  context "when the fix does not exist" do
    it "raises ArgumentError" do
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "input text")
      opts = { input: input_file, verbose: false, debug: false }
      executor = Storyfix::Executor.new(db: db, opts: opts)

      expect { executor.run("NonexistentFix", []) }
        .to raise_error(ArgumentError, /Fix 'NonexistentFix' not found/)
    end
  end

  context "with verbose option enabled" do
    it "outputs progress messages to stderr" do
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "input text")
      opts = { input: input_file, verbose: true, debug: false }
      executor = Storyfix::Executor.new(db: db, opts: opts)
      stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
        status: 200,
        body: { choices: [{ message: { content: "output" } }] }.to_json
      )

      expect { executor.run("FixSpelling", ["arg"]) }
        .to output(/Reading input.*Calling API.*Writing output/m).to_stderr
    end
  end

  context "with debug option enabled" do
    it "outputs debug info to stderr" do
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "input text")
      opts = { input: input_file, verbose: false, debug: true }
      executor = Storyfix::Executor.new(db: db, opts: opts)
      stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
        status: 200,
        body: { choices: [{ message: { content: "output" } }] }.to_json
      )

      expect { executor.run("FixSpelling", ["arg"]) }
        .to output(/Model:.*System:.*Prompt:/m).to_stderr
    end
  end

  context "with output file option" do
    it "writes result to the output file" do
      input_file = File.join(tmp_dir, "in.txt")
      output_file = File.join(tmp_dir, "out.txt")
      File.write(input_file, "input text")
      opts = { input: input_file, output: output_file, verbose: false, debug: false }
      executor = Storyfix::Executor.new(db: db, opts: opts)
      stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
        status: 200,
        body: { choices: [{ message: { content: "file output" } }] }.to_json
      )

      executor.run("FixSpelling", ["arg"])

      expect(File.read(output_file)).to eq("file output")
    end
  end
end
