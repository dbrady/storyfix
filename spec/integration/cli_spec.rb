require "spec_helper"
require "open3"
require "tmpdir"

RSpec.describe "CLI Integration" do
  let(:bin_path) { File.expand_path("../../bin/storyfix", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, "storyfix.db") }

  around do |example|
    old_xdg = ENV["XDG_CONFIG_HOME"]
    ENV["XDG_CONFIG_HOME"] = tmp_dir
    
    example.run
    
    ENV["XDG_CONFIG_HOME"] = old_xdg
    FileUtils.remove_entry(tmp_dir)
  end

  def run_cli(*args)
    stdout, stderr, status = Open3.capture3("ruby", bin_path, *args)
    [stdout, stderr, status]
  end

  it "shows help with --help" do
    stdout, _, status = run_cli("--help")
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include("Usage:")
  end

  it "shows help with no arguments" do
    stdout, _, status = run_cli
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include("Usage:")
  end

  it "can add and list a fix" do
    _, _, status = run_cli("add", "myfix", "My description", "Fix {{1}}.")
    expect(status.exitstatus).to eq(0)

    stdout, _, status = run_cli("list")
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include("myfix - My description")
  end
end
