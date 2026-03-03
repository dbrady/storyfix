require "optimist"
require "colorize"

module Storyfix
  class CLI
    def self.run(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv.dup
      @db = Database.new
      Storyfix::Migrator.auto_initialize(@db.connection)
      @setting_store = Setting.new(@db.connection)
      @fix_store = Fix::Store.new(@db.connection)
    end

    def execute
      @opts = Optimist.options(@argv) do
        version "StoryFix version #{Storyfix::VERSION}"
        banner <<~BANNER
          StoryFix - Apply LLM fixes to text

          Usage:
            storyfix <fix_name> [args...] [options]
            storyfix list
            storyfix add <fix_name> <description> <body>
            storyfix show <fix_name>
            storyfix remove <fix_name>
            storyfix list-configs
            storyfix get-config <key>
            storyfix set-config <key> <value>

          Options:
        BANNER
        opt :model, "Model to use", type: :string, short: "-m"
        opt :input, "Input file", type: :string, short: "-i"
        opt :output, "Output file", type: :string, short: "-o"
        opt :in_place, "Overwrite input file", short: "-I"
        opt :debug, "Debug output", short: "-d"
        opt :verbose, "Verbose output", short: "-V"

        conflicts :output, :in_place
      end

      Optimist.educate if @argv.empty?

      command = @argv.shift

      case command
      when "list"
        handle_list
      when "add"
        handle_add
      when "remove"
        handle_remove
      when "show"
        handle_show
      when "get-config"
        handle_get_config
      when "set-config"
        handle_set_config
      when "list-configs"
        handle_list_configs
      else
        handle_fix(command)
      end

      0
    rescue StoryfixError, ArgumentError => e
      Output.error(e.message)
      1
    rescue => e
      Output.error("unexpected error: #{e.message}")
      STDERR.puts e.backtrace if ENV["DEBUG"]
      1
    ensure
      @db.close
    end

    private

    def handle_list
      fixes = @fix_store.all
      if fixes.empty?
        puts "No fixes found."
      else
        fixes.each do |fix|
          puts "#{fix.name} - #{fix.description}"
        end
      end
    end

    def handle_add
      name = @argv.shift
      description = @argv.shift
      body = @argv.shift

      raise ArgumentError, "Usage: storyfix add <name> <description> <body>" unless name && description && body

      @fix_store.create(name: name, description: description, body: body)
      Output.success("Fix '#{name}' created.")
    end

    def handle_remove
      name = @argv.shift
      raise ArgumentError, "Usage: storyfix remove <name>" unless name

      if @fix_store.find(name)
        @fix_store.delete(name)
        Output.success("Fix '#{name}' removed.")
      else
        raise ArgumentError, "Fix '#{name}' not found."
      end
    end

    def handle_show
      name = @argv.shift
      raise ArgumentError, "Usage: storyfix show <name>" unless name

      fix = @fix_store.find(name)
      if fix
        puts "Name: #{fix.name}"
        puts "Description: #{fix.description}"
        puts "Body:\n#{fix.body}"
      else
        raise ArgumentError, "Fix '#{name}' not found."
      end
    end

    def handle_get_config
      key = @argv.shift
      raise ArgumentError, "Usage: storyfix get-config <key>" unless key

      val = @setting_store.get(key)
      if val
        puts val
      else
        raise ArgumentError, "Config key '#{key}' not found."
      end
    end

    def handle_set_config
      key = @argv.shift
      value = @argv.shift
      raise ArgumentError, "Usage: storyfix set-config <key> <value>" unless key && value

      @setting_store.set(key, value)
      Output.success("Config '#{key}' set.")
    end

    def handle_list_configs
      configs = @setting_store.all
      configs.each do |k, v|
        puts "#{k}=#{v}"
      end
    end

    def handle_fix(fix_name)
      executor = Executor.new(db: @db.connection, opts: @opts)
      executor.run(fix_name, @argv)
    end
  end
end
