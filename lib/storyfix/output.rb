require "colorize"

module Storyfix
  module Output
    class << self
      def error(msg)
        $stderr.puts "storyfix: error: #{msg}".colorize(:red)
      end

      def warn(msg)
        $stderr.puts "storyfix: warning: #{msg}".colorize(:yellow)
      end

      def info(msg)
        $stderr.puts "storyfix: #{msg}".colorize(:cyan)
      end

      def debug(msg)
        $stderr.puts "storyfix: debug: #{msg}".colorize(:light_black)
      end

      def success(msg)
        $stderr.puts "storyfix: success: #{msg}".colorize(:green)
      end
    end
  end
end
