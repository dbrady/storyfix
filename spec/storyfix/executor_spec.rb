require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::Executor do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "test.db") }
  let(:db) { Extralite::Database.new(db_path) }

  before do
    Storyfix::Schema.apply(db)
    Storyfix::Migrator.seed_defaults(db)

    db.execute("INSERT INTO fixes (name, description, body) VALUES ('test', 'desc', 'Fix {{1}}.')")
    db.execute("INSERT INTO settings (key, value) VALUES ('api-key', 'fake-key')")
  end

  after do
    db.close
    FileUtils.remove_entry(tmp_dir)
  end

  it "executes a fix and calls the API" do
    input_file = File.join(tmp_dir, "in.txt")
    File.write(input_file, "input text")

    opts = { input: input_file, verbose: false, debug: false }
    executor = described_class.new(db: db, opts: opts)

    stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
      status: 200,
      body: { choices: [{ message: { content: "Fixed text." } }] }.to_json
    )

    expect {
      executor.run("test", ["this"])
    }.to output("Fixed text.").to_stdout
  end

  it "raises ArgumentError when fix not found" do
    input_file = File.join(tmp_dir, "in.txt")
    File.write(input_file, "input text")

    opts = { input: input_file, verbose: false, debug: false }
    executor = described_class.new(db: db, opts: opts)

    expect {
      executor.run("nonexistent", [])
    }.to raise_error(ArgumentError, /Fix 'nonexistent' not found/)
  end

  it "outputs verbose messages when verbose is true" do
    input_file = File.join(tmp_dir, "in.txt")
    File.write(input_file, "input text")

    opts = { input: input_file, verbose: true, debug: false }
    executor = described_class.new(db: db, opts: opts)

    stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
      status: 200,
      body: { choices: [{ message: { content: "output" } }] }.to_json
    )

    expect {
      executor.run("test", ["arg"])
    }.to output(/Reading input.*Calling API.*Writing output/m).to_stderr
  end

  it "outputs debug messages when debug is true" do
    input_file = File.join(tmp_dir, "in.txt")
    File.write(input_file, "input text")

    opts = { input: input_file, verbose: false, debug: true }
    executor = described_class.new(db: db, opts: opts)

    stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
      status: 200,
      body: { choices: [{ message: { content: "output" } }] }.to_json
    )

    expect {
      executor.run("test", ["arg"])
    }.to output(/Model:.*System:.*Prompt:/m).to_stderr
  end

  it "writes output to file when output option is specified" do
    input_file = File.join(tmp_dir, "in.txt")
    output_file = File.join(tmp_dir, "out.txt")
    File.write(input_file, "input text")

    opts = { input: input_file, output: output_file, verbose: false, debug: false }
    executor = described_class.new(db: db, opts: opts)

    stub_request(:post, Storyfix::ApiClient::ENDPOINT).to_return(
      status: 200,
      body: { choices: [{ message: { content: "file output" } }] }.to_json
    )

    executor.run("test", ["arg"])

    expect(File.read(output_file)).to eq("file output")
  end
end
