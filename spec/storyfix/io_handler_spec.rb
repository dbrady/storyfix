require "spec_helper"
require "tmpdir"

RSpec.describe Storyfix::IOHandler do
  let(:tmp_dir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  it "reads from file" do
    input_file = File.join(tmp_dir, "in.txt")
    File.write(input_file, "file content")

    io = described_class.new(input: input_file)
    expect(io.read_input).to eq("file content")
  end

  it "reads from stdin when not a tty" do
    io = described_class.new({})

    allow($stdin).to receive(:tty?).and_return(false)
    allow($stdin).to receive(:read).and_return("stdin content")

    expect(io.read_input).to eq("stdin content")
  end

  it "raises StoryfixError when no input and stdin is a tty" do
    io = described_class.new({})

    allow($stdin).to receive(:tty?).and_return(true)

    expect { io.read_input }.to raise_error(Storyfix::StoryfixError, /No input provided/)
  end

  it "writes to file" do
    output_file = File.join(tmp_dir, "out.txt")

    io = described_class.new(output: output_file)
    io.write_output("output content")

    expect(File.read(output_file)).to eq("output content\n")
  end

  it "writes to stdout when no output file specified" do
    io = described_class.new({})
    expect { io.write_output("stdout content") }.to output("stdout content\n").to_stdout
  end

  it "writes in place" do
    file = File.join(tmp_dir, "inplace.txt")
    File.write(file, "old")

    io = described_class.new(input: file, in_place: true)
    io.write_output("new")

    expect(File.read(file)).to eq("new\n")
  end

  it "reads input in place mode when file exists" do
    file = File.join(tmp_dir, "inplace_read.txt")
    File.write(file, "content to read")

    io = described_class.new(input: file, in_place: true)
    expect(io.read_input).to eq("content to read")
  end

  it "raises error if in_place but no input" do
    io = described_class.new(in_place: true)
    expect { io.read_input }.to raise_error(Storyfix::StoryfixError, /requires an --input file/)
  end

  it "raises error if in_place and input file does not exist" do
    io = described_class.new(input: File.join(tmp_dir, "missing.txt"), in_place: true)
    expect { io.read_input }.to raise_error(Storyfix::StoryfixError, /Input file does not exist/)
  end

  it "raises error if input file missing" do
    io = described_class.new(input: File.join(tmp_dir, "missing.txt"))
    expect { io.read_input }.to raise_error(Storyfix::StoryfixError, /does not exist/)
  end
end
