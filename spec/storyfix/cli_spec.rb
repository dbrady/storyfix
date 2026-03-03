require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::CLI do
  let(:tmp_dir) { Dir.mktmpdir }

  around do |example|
    old_xdg = ENV["XDG_CONFIG_HOME"]
    ENV["XDG_CONFIG_HOME"] = tmp_dir
    example.run
    ENV["XDG_CONFIG_HOME"] = old_xdg
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  it "calls Optimist.educate when argv is empty" do
    expect(Optimist).to receive(:educate)
    described_class.run([])
  end

  describe "list command" do
    it "shows 'No fixes found' when empty" do
      expect { described_class.run(["list"]) }.to output(/No fixes found/).to_stdout
    end

    it "lists fixes with name and description" do
      described_class.run(["add", "myfix", "My description", "body"])
      expect { described_class.run(["list"]) }.to output(/myfix - My description/).to_stdout
    end
  end

  describe "add command" do
    it "creates a fix and shows success message" do
      expect { described_class.run(["add", "testfix", "desc", "body"]) }
        .to output(/Fix 'testfix' created/).to_stderr
    end

    it "returns 1 when missing arguments" do
      expect(described_class.run(["add", "only-name"])).to eq(1)
    end
  end

  describe "remove command" do
    it "removes a fix and shows success message" do
      described_class.run(["add", "delfix", "desc", "body"])
      expect { described_class.run(["remove", "delfix"]) }
        .to output(/Fix 'delfix' removed/).to_stderr
    end

    it "returns 1 when fix not found" do
      expect(described_class.run(["remove", "nonexistent"])).to eq(1)
    end

    it "returns 1 when no name given" do
      expect(described_class.run(["remove"])).to eq(1)
    end
  end

  describe "show command" do
    it "shows fix details" do
      described_class.run(["add", "showfix", "Show desc", "Show body"])
      expect { described_class.run(["show", "showfix"]) }
        .to output(/Name: showfix.*Description: Show desc.*Body:\nShow body/m).to_stdout
    end

    it "returns 1 when fix not found" do
      expect(described_class.run(["show", "nonexistent"])).to eq(1)
    end

    it "returns 1 when no name given" do
      expect(described_class.run(["show"])).to eq(1)
    end
  end

  describe "set-config command" do
    it "sets a config value" do
      expect { described_class.run(["set-config", "test-key", "test-val"]) }
        .to output(/Config 'test-key' set/).to_stderr
    end

    it "returns 1 when missing arguments" do
      expect(described_class.run(["set-config", "only-key"])).to eq(1)
    end
  end

  describe "get-config command" do
    it "gets a config value" do
      described_class.run(["set-config", "mykey", "myval"])
      expect { described_class.run(["get-config", "mykey"]) }
        .to output(/myval/).to_stdout
    end

    it "returns 1 when key not found" do
      expect(described_class.run(["get-config", "nonexistent"])).to eq(1)
    end

    it "returns 1 when no key given" do
      expect(described_class.run(["get-config"])).to eq(1)
    end
  end

  describe "list-configs command" do
    it "lists all config values" do
      described_class.run(["set-config", "k1", "v1"])
      described_class.run(["set-config", "k2", "v2"])
      output = capture_stdout { described_class.run(["list-configs"]) }
      expect(output).to include("k1=v1")
      expect(output).to include("k2=v2")
    end
  end

  describe "fix execution" do
    it "returns 1 when fix not found" do
      expect(described_class.run(["nonexistent-fix"])).to eq(1)
    end
  end

  describe "error handling" do
    it "returns 1 and prints error for StoryfixError" do
      described_class.run(["add", "badinput", "desc", "body {{1}}"])
      result = nil
      expect {
        result = described_class.run(["badinput"])
      }.to output(/error/).to_stderr
      expect(result).to eq(1)
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(Storyfix::Executor).to receive(:run).and_raise(RuntimeError, "boom")
      described_class.run(["add", "boom", "desc", "body"])

      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "test")

      result = nil
      expect {
        result = described_class.run(["boom", "-i", input_file])
      }.to output(/unexpected error: boom/).to_stderr
      expect(result).to eq(1)
    end

    it "prints backtrace to STDERR when DEBUG is set" do
      allow_any_instance_of(Storyfix::Executor).to receive(:run).and_raise(RuntimeError, "debug-error")
      described_class.run(["add", "debugfix", "desc", "body"])

      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "test")
      stderr_file = File.join(tmp_dir, "stderr.txt")

      old_debug = ENV["DEBUG"]
      ENV["DEBUG"] = "1"
      original_stderr = STDERR.dup
      STDERR.reopen(stderr_file, "w")
      begin
        described_class.run(["debugfix", "-i", input_file])
      ensure
        STDERR.flush
        STDERR.reopen(original_stderr)
        ENV["DEBUG"] = old_debug
      end

      captured = File.read(stderr_file)
      expect(captured).to include("debug-error")
      expect(captured).to match(/\.rb:\d+/)
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
