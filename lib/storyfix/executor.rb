module Storyfix
  class Executor
    def initialize(db:, opts:)
      @db = db
      @opts = opts
      @setting_store = Setting.new(@db)
      @fix_store = Fix::Store.new(@db)
      @config = Config.new(@setting_store, ENV, @opts)
      @io = IOHandler.new(@opts)
    end

    def run(fix_name, args)
      fix = @fix_store.find(fix_name)
      raise ArgumentError, "Fix '#{fix_name}' not found." unless fix
      
      user_message = fix.render(args)
      input_text = @io.read_input
      
      Output.info("Reading input...") if @opts[:verbose]
      
      system_prompt = @config.system_prompt.to_s
      system_prompt += "

NOTE: If the user request violates safety guidelines, you must refuse cleanly. Do not output any preamble."
      
      full_user_message = "#{user_message}

#{input_text}"
      
      if @opts[:debug]
        Output.debug("Model: #{@config.resolved_model}")
        Output.debug("System: #{system_prompt}")
        Output.debug("Prompt: #{full_user_message}")
      end
      
      Output.info("Calling API...") if @opts[:verbose]
      
      client = ApiClient.new(@config.api_key, @config.resolved_model, @config.get("api-timeout") || 60)
      output_text = client.call(system_prompt, full_user_message)
      
      Output.info("Writing output...") if @opts[:verbose]
      
      @io.write_output(output_text)
    end
  end
end
