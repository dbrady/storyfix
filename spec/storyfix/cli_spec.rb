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

  context "with no arguments" do
    it "calls Optimist.educate" do
      expect(Optimist).to receive(:educate)
      Storyfix::CLI.run([])
    end
  end

  context "with the list command" do
    context "when no fixes exist" do
      it "outputs 'No fixes found'" do
        expect { Storyfix::CLI.run(["list"]) }.to output(/No fixes found/).to_stdout
      end
    end

    context "when fixes exist" do
      it "outputs fix names and descriptions" do
        Storyfix::CLI.run(["add", "FixSpelling", "Corrects spelling errors", "Fix spelling"])

        expect { Storyfix::CLI.run(["list"]) }.to output(/FixSpelling - Corrects spelling errors/).to_stdout
      end
    end
  end

  context "with the add command" do
    context "with valid arguments" do
      it "creates the fix" do
        expect { Storyfix::CLI.run(["add", "FixGrammar", "Fixes grammar", "body"]) }
          .to output(/Fix 'FixGrammar' created/).to_stderr
      end
    end

    context "with missing arguments" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["add", "only-name"])).to eq(1)
      end
    end
  end

  context "with the remove command" do
    context "when the fix exists" do
      it "removes the fix" do
        Storyfix::CLI.run(["add", "FixTense", "Changes tense", "body"])

        expect { Storyfix::CLI.run(["remove", "FixTense"]) }
          .to output(/Fix 'FixTense' removed/).to_stderr
      end
    end

    context "when the fix does not exist" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["remove", "nonexistent"])).to eq(1)
      end
    end

    context "with no name given" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["remove"])).to eq(1)
      end
    end
  end

  context "with the show command" do
    context "when the fix exists" do
      it "outputs fix details" do
        Storyfix::CLI.run(["add", "FixPOV", "Changes point of view", "Change POV"])

        expect { Storyfix::CLI.run(["show", "FixPOV"]) }
          .to output(/Name: FixPOV.*Description: Changes point of view.*Body:\nChange POV/m).to_stdout
      end
    end

    context "when the fix does not exist" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["show", "nonexistent"])).to eq(1)
      end
    end

    context "with no name given" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["show"])).to eq(1)
      end
    end
  end

  context "with the set-config command" do
    context "with valid arguments" do
      it "sets the config value" do
        expect { Storyfix::CLI.run(["set-config", "test-key", "test-val"]) }
          .to output(/Config 'test-key' set/).to_stderr
      end
    end

    context "with missing arguments" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["set-config", "only-key"])).to eq(1)
      end
    end
  end

  context "with the get-config command" do
    context "when the key exists" do
      it "outputs the value" do
        Storyfix::CLI.run(["set-config", "mykey", "myval"])

        expect { Storyfix::CLI.run(["get-config", "mykey"]) }
          .to output(/myval/).to_stdout
      end
    end

    context "when the key does not exist" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["get-config", "nonexistent"])).to eq(1)
      end
    end

    context "with no key given" do
      it "returns 1" do
        expect(Storyfix::CLI.run(["get-config"])).to eq(1)
      end
    end
  end

  context "with the list-configs command" do
    it "outputs all config values" do
      Storyfix::CLI.run(["set-config", "k1", "v1"])
      Storyfix::CLI.run(["set-config", "k2", "v2"])

      output = capture_stdout { Storyfix::CLI.run(["list-configs"]) }

      expect(output).to include("k1=v1")
      expect(output).to include("k2=v2")
    end
  end

  context "with a fix name that does not exist" do
    it "returns 1" do
      expect(Storyfix::CLI.run(["NonexistentFix"])).to eq(1)
    end
  end

  context "when a StoryfixError is raised" do
    it "returns 1 and prints the error" do
      Storyfix::CLI.run(["add", "FixArgs", "Requires args", "body {{1}}"])

      result = nil
      expect {
        result = Storyfix::CLI.run(["FixArgs"])
      }.to output(/error/).to_stderr

      expect(result).to eq(1)
    end
  end

  context "when an unexpected error is raised" do
    it "returns 1 and prints 'unexpected error'" do
      # Note: allow_any_instance_of is discouraged but CLI lacks DI for Executor
      allow_any_instance_of(Storyfix::Executor).to receive(:run).and_raise(RuntimeError, "boom")
      Storyfix::CLI.run(["add", "FixBoom", "desc", "body"])
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "test")

      result = nil
      expect {
        result = Storyfix::CLI.run(["FixBoom", "-i", input_file])
      }.to output(/unexpected error: boom/).to_stderr

      expect(result).to eq(1)
    end
  end

  context "when DEBUG is set and an error occurs" do
    it "prints the backtrace to STDERR" do
      allow_any_instance_of(Storyfix::Executor).to receive(:run).and_raise(RuntimeError, "debug-error")
      Storyfix::CLI.run(["add", "FixDebug", "desc", "body"])
      input_file = File.join(tmp_dir, "in.txt")
      File.write(input_file, "test")
      stderr_file = File.join(tmp_dir, "stderr.txt")

      old_debug = ENV["DEBUG"]
      ENV["DEBUG"] = "1"
      original_stderr = STDERR.dup
      STDERR.reopen(stderr_file, "w")
      begin
        Storyfix::CLI.run(["FixDebug", "-i", input_file])
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
