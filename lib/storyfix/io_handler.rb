module Storyfix
  class IOHandler
    def initialize(opts)
      @opts = opts
    end

    def read_input
      validate_input!

      if @opts[:input]
        File.read(@opts[:input])
      elsif !$stdin.tty?
        $stdin.read
      else
        raise StoryfixError, "No input provided. Use --input or pipe data to stdin."
      end
    end

    def write_output(content)
      if @opts[:in_place]
        File.write(@opts[:input], content)
      elsif @opts[:output]
        File.write(@opts[:output], content)
      else
        $stdout.print(content)
      end
    end

    private

    def validate_input!
      if @opts[:in_place]
        raise StoryfixError, "--in-place requires an --input file" unless @opts[:input]
        raise StoryfixError, "Input file does not exist" unless File.exist?(@opts[:input])
      end

      if @opts[:input] && !File.exist?(@opts[:input])
        raise StoryfixError, "Input file does not exist: #{@opts[:input]}"
      end
    end
  end
end
