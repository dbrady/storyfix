module Storyfix
  class Config
    def initialize(setting_store, env = ENV, cli_options = {})
      @setting_store = setting_store
      @env = env
      @cli_options = cli_options
    end

    def get(key)
      if @cli_options.key?(key.to_sym) && !@cli_options[key.to_sym].nil?
        return @cli_options[key.to_sym]
      end
      
      env_key = key.upcase.tr('-', '_')
      if @env.key?("STORYFIX_#{env_key}")
        return @env["STORYFIX_#{env_key}"]
      end
      if @env.key?(env_key) && env_key == 'OPENROUTER_API_KEY'
        return @env[env_key]
      end

      @setting_store.get(key)
    end

    def api_key
      get("openrouter-api-key") || get("api-key") || @env["OPENROUTER_API_KEY"]
    end

    def system_prompt
      get("system-prompt-fix")
    end

    def model_for(name_or_alias)
      return nil unless name_or_alias
      
      alias_val = get("model-#{name_or_alias}")
      return alias_val if alias_val
      
      name_or_alias
    end

    def default_model
      get("default-model")
    end
    
    def resolved_model
      model_for(get("model") || default_model)
    end
  end
end
